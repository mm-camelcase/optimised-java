# psrecord

`psrecord` is a lightweight Python-based tool used to monitor and record the CPU and memory usage of a process over time. It’s particularly useful for profiling applications to understand their resource consumption during execution. The tool captures data at regular intervals and can optionally output it as a real-time graph or save the results to a log file for further analysis.

see the [website](https://github.com/astrofrog/psrecord) for instalation instructions

```sh
# record CPU and memory usage in 1 second intervals
psrecord 12345 --log native.txt --plot native.png --interval 1
```

where `12345` is an example of a process ID which you can find with `ps` or `top`, or in this case a docker process using `docker top user-service`
