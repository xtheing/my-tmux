#!/bin/bash

# 状态信息缓存目录
CACHE_DIR="/tmp/tmux_status_cache"
STATS_FILE="$CACHE_DIR/stats"

# 创建缓存目录
mkdir -p "$CACHE_DIR"

# 初始化网络统计
if [ ! -f "$CACHE_DIR/net_rx" ]; then
    # 获取默认网络接口
    INTERFACE=$(ip route | grep default | head -1 | awk '{print $5}')
    if [ -z "$INTERFACE" ]; then
        INTERFACE="eth0"
    fi

    RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
    TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
    echo "$RX_BYTES" > "$CACHE_DIR/net_rx"
    echo "$TX_BYTES" > "$CACHE_DIR/net_tx"
    echo "$(date +%s)" > "$CACHE_DIR/net_time"
fi

# 获取网络速度
get_network_speed() {
    INTERFACE=$(ip route | grep default | head -1 | awk '{print $5}')
    if [ -z "$INTERFACE" ]; then
        INTERFACE="eth0"
    fi

    # 检查接口是否存在
    if [ ! -f "/sys/class/net/$INTERFACE/statistics/rx_bytes" ]; then
        echo "↓0KB/s ↑0KB/s"
        return
    fi

    CURRENT_RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
    CURRENT_TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
    CURRENT_TIME=$(date +%s)

    LAST_RX=$(cat "$CACHE_DIR/net_rx" 2>/dev/null || echo 0)
    LAST_TX=$(cat "$CACHE_DIR/net_tx" 2>/dev/null || echo 0)
    LAST_TIME=$(cat "$CACHE_DIR/net_time" 2>/dev/null || echo $CURRENT_TIME)

    # 计算时间差
    TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
    if [ $TIME_DIFF -eq 0 ]; then
        TIME_DIFF=1
    fi

    # 计算速度差 (字节/秒)
    RX_SPEED=$(( (CURRENT_RX - LAST_RX) / TIME_DIFF ))
    TX_SPEED=$(( (CURRENT_TX - LAST_TX) / TIME_DIFF ))

    # 转换为KB/s，如果为负数则设为0
    if [ $RX_SPEED -lt 0 ]; then RX_SPEED=0; fi
    if [ $TX_SPEED -lt 0 ]; then TX_SPEED=0; fi

    RX_KB=$((RX_SPEED / 1024))
    TX_KB=$((TX_SPEED / 1024))

    # 更新缓存
    echo "$CURRENT_RX" > "$CACHE_DIR/net_rx"
    echo "$CURRENT_TX" > "$CACHE_DIR/net_tx"
    echo "$CURRENT_TIME" > "$CACHE_DIR/net_time"

    # 输出格式化结果
    printf "↓%dKB/s ↑%dKB/s" $RX_KB $TX_KB
}

# 获取内存使用率
get_memory_usage() {
    if [ -f /proc/meminfo ]; then
        TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        if [ -z "$AVAILABLE" ]; then
            # 对于没有MemAvailable的旧系统
            FREE=$(grep MemFree /proc/meminfo | awk '{print $2}')
            BUFFERS=$(grep Buffers /proc/meminfo | awk '{print $2}')
            CACHED=$(grep "^Cached" /proc/meminfo | awk '{print $2}')
            AVAILABLE=$((FREE + BUFFERS + CACHED))
        fi
        USED=$((TOTAL - AVAILABLE))
        USAGE=$((USED * 100 / TOTAL))
        echo "${USAGE}%"
    else
        echo "N/A"
    fi
}

# 获取CPU使用率
get_cpu_usage() {
    if [ -f /proc/stat ]; then
        # 读取CPU统计信息
        CPU_LINE=$(head -1 /proc/stat)
        CPU_VALUES=$(echo $CPU_LINE | sed 's/^cpu //')

        # 解析CPU时间
        IDLE=$(echo $CPU_VALUES | awk '{print $4}')
        TOTAL=0
        for value in $CPU_VALUES; do
            TOTAL=$((TOTAL + value))
        done

        # 读取上次的数据
        if [ -f "$CACHE_DIR/cpu_idle" ] && [ -f "$CACHE_DIR/cpu_total" ]; then
            LAST_IDLE=$(cat "$CACHE_DIR/cpu_idle")
            LAST_TOTAL=$(cat "$CACHE_DIR/cpu_total")

            # 计算差值
            IDLE_DIFF=$((IDLE - LAST_IDLE))
            TOTAL_DIFF=$((TOTAL - LAST_TOTAL))

            if [ $TOTAL_DIFF -gt 0 ]; then
                # 计算CPU使用率
                CPU_USAGE=$((100 - (IDLE_DIFF * 100 / TOTAL_DIFF)))
                if [ $CPU_USAGE -lt 0 ]; then CPU_USAGE=0; fi
                if [ $CPU_USAGE -gt 100 ]; then CPU_USAGE=100; fi
            else
                CPU_USAGE=0
            fi
        else
            CPU_USAGE=0
        fi

        # 保存当前数据
        echo "$IDLE" > "$CACHE_DIR/cpu_idle"
        echo "$TOTAL" > "$CACHE_DIR/cpu_total"

        echo "${CPU_USAGE}%"
    else
        echo "N/A"
    fi
}

# 根据参数返回对应信息
case "$1" in
    "network")
        get_network_speed
        ;;
    "memory")
        get_memory_usage
        ;;
    "cpu")
        get_cpu_usage
        ;;
    *)
        echo "Usage: $0 {network|memory|cpu}"
        exit 1
        ;;
esac

