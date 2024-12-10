#!/bin/bash

CPU_MAXLOAD=100
CONNECTION_MAX=100 
TIME_SLEEP=2
CPU_CHECK_DURATION=10

declare -A cpu_usage

check_cpu_usage() {

    ps_output=$(ps -eo pid,%cpu --sort=-%cpu | awk 'NR>1 {print $1, $2}')
    
    while IFS= read -r line; do
        pid=$(echo "$line" | awk '{print $1}')
        cpu=$(echo "$line" | awk '{print $2}')
        cpu_int=${cpu//.*}
        
        if [ "$cpu_int" -gt "$CPU_MAXLOAD" ]; then 
            
            if [[ -n "${cpu_usage[$pid]}" ]]; then
                cpu_usage["$pid"]=$((cpu_usage["$pid"] + TIME_SLEEP))
            else
                
                cpu_usage["$pid"]=$TIME_SLEEP
            fi
            
            echo "Процесс $pid использует $cpu% CPU (время: ${cpu_usage[$pid]} секунд)"
            
            if [[ ${cpu_usage["$pid"]} -ge $CPU_CHECK_DURATION ]]; then
                echo "Убиваем процесс $pid за использование CPU более $CPU_CHECK_DURATION секунд."
                kill -9 $pid
                unset cpu_usage["$pid"] 
            fi
        else 
            
            if [[ -n "${cpu_usage[$pid]}" ]]; then
                echo "Процесс $pid больше не превышает порог использования CPU."
            fi
        fi
    done <<< "$ps_output"
}

check_connections() {
    echo "Проверка открытых соединений..."
    n=$(netstat -a | grep ESTAB | wc -l)
    echo "Количество открытых соединений: $n"

    if [ "$n" -gt "$CONNECTION_MAX" ]; then
        echo "Внимание: Возможна DDOS-атака!"
    fi
}

while true; do
    check_cpu_usage
    check_connections
    sleep $TIME_SLEEP 
done
