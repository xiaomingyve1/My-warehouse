#!/usr/bin/env bash
# diy-part2.sh (强力版)
# 目的：确保 nss/qca 相关驱动能出现在 package/ 中；打印尽可能多的调试信息用于 CI 日志
set -euo pipefail
export PATH="$PATH:/usr/bin:/bin"

echo ">>> diy-part2.sh start: $(date) <<<"

# 进入 openwrt 源代码目录（如果仓库里有 openwrt 子目录）
if [ -d "./openwrt" ]; then
  cd openwrt
  echo "cd into ./openwrt"
fi
WORKDIR="$(pwd)"
echo "workdir: ${WORKDIR}"

# 备份 feeds.conf.default
if [ -f feeds.conf.default ]; then
  cp -vf feeds.conf.default feeds.conf.default.bak || true
  echo "Backed up feeds.conf.default"
else
  echo "feeds.conf.default not found; creating new one"
  touch feeds.conf.default
fi

# helper: 添加 feed（如果不存在则追加）
ensure_feed() {
  local line="$1"
  local marker="$2"
  if ! grep -Fq "$marker" feeds.conf.default 2>/dev/null; then
    echo "Adding feed => $line"
    echo "$line" >> feeds.conf.default
  else
    echo "Feed marker '$marker' already present"
  fi
}

# 常见 candidate feeds（官方 nss 和 VIKINGYFY）
ensure_feed "src-git nss_packages https://github.com/openwrt/nss_packages.git" "nss_packages"
ensure_feed "src-git viking_packages https://github.com/VIKINGYFY/packages.git" "viking_packages"

echo "=== feeds.conf.default now ==="
cat feeds.conf.default || true
echo "================================"

# 更新并安装 feeds
echo "Running ./scripts/feeds clean && ./scripts/feeds update -i"
./scripts/feeds clean || true
./scripts/feeds update -i || true

echo "Running ./scripts/feeds install -a -f"
./scripts/feeds install -a -f || true

# 显示目录结构供日志查看
echo "==== top-level listing ===="
ls -la || true
echo "==== package dir ===="
ls -la package || true
echo "==== feeds dir ===="
ls -la feeds || true

# 搜索现有的可能相关包
echo "==== Searching for qca / nss / kmod-qca names in package/ and feeds/ ===="
grep -R --line-number --exclude-dir=.git -e "qca" -e "nss" -e "kmod-qca" package feeds 2>/dev/null || true
find package feeds -maxdepth 4 -type d -iname "*qca*" -or -iname "*nss*" -print || true

# 如果目标包缺失 -> 采取强力补救：克隆远程 repo 并搬入 package/
TARGETS=("kmod-qca-nss-drv" "kmod-qca-nss" "kmod-qca" "qca-nss" "qca")
NEED_MOVE=0
for t in "${TARGETS[@]}"; do
  if [ -d "package/$t" ]; then
    echo "Found existing package/$t"
  else
    NEED_MOVE=1
  fi
done

if [ "$NEED_MOVE" -eq 1 ]; then
  echo "Some qca/nss packages are missing. Attempting to fetch from known repos..."
  TMPDIR="$(mktemp -d)"
  echo "tmpdir: $TMPDIR"

  # 尝试 1: 官方 nss_packages
  echo "Cloning https://github.com/openwrt/nss_packages.git ..."
  git clone --depth=1 https://github.com/openwrt/nss_packages.git "$TMPDIR/nss_packages" || true
  echo "Looking for matching dirs..."
  for p in $(find "$TMPDIR/nss_packages" -maxdepth 3 -type d -iname "*qca*" -o -iname "*nss*" -print 2>/dev/null); do
    echo "Candidate from nss_packages: $p"
    base=$(basename "$p")
    if [ ! -d "package/$base" ]; then
      echo " -> moving $p to package/$base"
      mv -vf "$p" "package/$base" || true
    else
      echo " -> package/$base already exists; skip"
    fi
  done

  # 尝试 2: VIKINGYFY packages（如果仍然没有）
  echo "Cloning https://github.com/VIKINGYFY/packages.git ..."
  git clone --depth=1 https://github.com/VIKINGYFY/packages.git "$TMPDIR/viking_packages" || true
  for p in $(find "$TMPDIR/viking_packages" -maxdepth 4 -type d -iname "*qca*" -o -iname "*nss*" -print 2>/dev/null); do
    echo "Candidate from viking_packages: $p"
    base=$(basename "$p")
    if [ ! -d "package/$base" ]; then
      echo " -> moving $p to package/$base"
      mv -vf "$p" "package/$base" || true
    else
      echo " -> package/$base already exists; skip"
    fi
  done

  # 如果还有其他可能的目录名（容错拷贝所有 kmod-*qca*）
  echo "Searching and copy any 'kmod-*qca*' or '*qca*nss*' dirs found"
  for p in $(find "$TMPDIR" -maxdepth 5 -type d -iname "kmod-*qca*" -o -iname "*qca*nss*" -print 2>/dev/null); do
    base=$(basename "$p")
    if [ ! -d "package/$base" ]; then
      echo " -> copying $p to package/$base"
      cp -a "$p" "package/$base" || true
    fi
  done

  rm -rf "$TMPDIR" || true
else
  echo "All target qca/nss packages appear present, skipping fetch."
fi

# 再次刷新 feeds/package 索引
echo "Re-running ./scripts/feeds install -a -f"
./scripts/feeds install -a -f || true

# 打印最终结果
echo "==== Final package listing for qca/nss candidates ===="
for q in "${TARGETS[@]}"; do
  if [ -d "package/$q" ]; then
    echo "OK -> package/$q exists"
    ls -la "package/$q" || true
  else
    echo "MISSING -> package/$q"
  fi
done

# 额外：列出包含 kmod-qca 或 qca-nss 的所有 package 目录（供日志）
find package -maxdepth 2 -type d -iname "*qca*" -o -iname "*nss*" -print || true

# 输出 .config 中 kernel 相关信息（如果存在）
if [ -f .config ]; then
  echo "==== Kernel-related lines from .config ===="
  grep -i "KERNEL\|kernel\|CONFIG_KERNEL" .config || true
fi

echo ">>> diy-part2.sh end: $(date) <<<"
