#include <boost/coroutine/all.hpp>
#include <boost/bind.hpp>

namespace coro = boost::coro;

bool b_quit = false;

// --- The Average Task ---
// Computes the average of the input data and then yields execution back to the main task
//-------------------------
// struct average_args - data for the task
// average_yield() - wrapper for yielding execution back to the main task
// average_task() - the task logic
// ------------------------
struct average_args
{
	int * source;
	int sum;
	int count;
	int average;
	int task_;
};
typedef coro::coroutine< void(average_args*) > coro_avg_t;
void average_task(coro_avg_t::self_t& self, average_args* args)
{
	args->sum = 0;
	args->count = 0;
	args->average = 0;
	while (true)
	{
		args->sum += *args->source;
		++args->count;
		args->average = args->sum / args->count;
		self.yield();
	}

	printf("ERROR: should not reach the end of average function\n");
}

// --- The Input Task ---
// Reads a number as input from the console and then yields execution back to the main task
// ----------------------
// struct input_args - data for the task
// input_yield() - wrapper for yielding execution back to the main task
// input_task() - the task logic
// ----------------------
struct input_args
{
	average_args* aa;
	int * target;
	int task_;
};
typedef coro::coroutine< void(input_args*) > coro_input_t;
void input_task(coro_input_t::self_t& self, input_args* pia)
{
	while (true)
	{
		printf("number: ");
		if (!scanf_s("%d", pia->target))
		{
			b_quit = true;
			return;
		}
    
		self.yield();
	}

	printf("ERROR: should not reach the end of input function\n");
}

void main()
{
	int share = -1;
	average_args aa = {&share};
	input_args ia = {&aa, &share};

	// construct the input task
	coro_input_t c_input( boost::bind( input_task, _1, &ia) );

	// construct the average task
	coro_avg_t c_average( boost::bind( average_task, _1, &aa ) );

	while (!b_quit)
	{
		c_input(&ia);
		c_average(&aa);
		printf("sum=%d count=%d average=%d\n", aa.sum, aa.count, aa.average);
	}
	
	printf("main: done\n");
}
