#pragma D option quiet
BEGIN 
{
	ckpt_stop_time = 0;
	ckpt_cont_time_total = 0;	
	ckpt_stop_count = 0;
	ckpt_cont_count = 0;
	wake = 0;
	wake_total = 0;
	wake_count = 0;
}

fbt:sls:sls_stop_proc:entry
{
	stop_time = timestamp;
}

fbt:sls:sls_stop_proc:return
{
	ckpt_stop_time += timestamp - stop_time;
	ckpt_stop_count += 1;
	stop_time = timestamp;
	sig = 1;
	ckpt_cont_time = timestamp;
}

proc:::signal-send
/sig == 1 && args[2] == SIGCONT/
{
	ckpt_cont_time_total += timestamp - ckpt_cont_time;
	ckpt_cont_count += 1;
	sig = 0;
	cont_sent = 1;
	wake = timestamp;
}

sched:::wakeup
/cont_sent == 1 && args[1]->p_pid == $1/
{
	wake_total += timestamp - wake;
	wake_count += 1;
	cont_sent = 0;
}
END 
{
	TO_MILI = 1000000;
	printf("%s: %d, %d, %d\n", "Chkpt Stop", 
			ckpt_stop_time, ckpt_stop_count,
			ckpt_stop_time / (TO_MILI * ckpt_stop_count));
	printf("%s: %d, %d, %d\n", "Chkpt Cont", 
			ckpt_cont_time_total, ckpt_cont_count,
			ckpt_cont_time_total / (TO_MILI *ckpt_cont_count));
	printf("%s: %d, %d, %d\n", "Wakeup", 
			wake_total, wake_count,
			wake_total/ (TO_MILI * wake_count));

}
