const std = @import("std");
const allocator = std.heap.page_allocator;
const Thread = std.Thread;
const Mutex = std.Thread.Mutex;

var rng = std.rand.DefaultPrng.init(0);

const Philosopher = struct {
    id: u16,
    left_fork: Mutex,
    right_fork: Mutex,
    apetite: u32,
};
fn dine(self: *Philosopher) void {
    while (self.apetite > 0) : (self.apetite -|= 1) {
        // think
        std.log.info("Philosopher {} is thinking", .{self.id});

        // attempt to grab forks (even philosophers prefer to grab left first)
        if (self.id % 2 == 0) {
            self.left_fork.lock();
            self.right_fork.lock();
        } else {
            self.right_fork.lock();
            self.left_fork.lock();
        }
        std.log.info("Philosopher {} is eating", .{self.id});
        // sleep for random time to add some unpredictability
        var rand_sleep = rng.random().int(u64) % 8 + 1;
        std.time.sleep(2 * 1000 * 1000 * 100 * rand_sleep);
        // defer the unlock in any order
        defer self.right_fork.unlock();
        defer self.left_fork.unlock();
    }
}

pub fn main() anyerror!void {
    const numPhilosophers: i16 = 10;
    const apetite: i16 = 10;
    // create forks and philosophers
    var forks: [if (numPhilosophers > 1) numPhilosophers else numPhilosophers + 1]Mutex = undefined;
    var i: u16 = 0;
    while (i < numPhilosophers) : (i += 1) {
        forks[i] = Mutex{};
    }

    var philosophers: [numPhilosophers]Philosopher = undefined;
    var threads: [numPhilosophers]Thread = undefined;
    i = 0;
    while (i < numPhilosophers) : (i += 1) {
        var left_fork = forks[i];
        var right_fork = if (i == numPhilosophers - 1) forks[0] else forks[i + 1];
        philosophers[i] = Philosopher{ .id = i + 1, .left_fork = left_fork, .right_fork = right_fork, .apetite = apetite };
        threads[i] = try Thread.spawn(Thread.SpawnConfig{}, dine, .{&philosophers[i]});
    }
    // await completion of threads
    i = 0;
    while (i < numPhilosophers) : (i += 1) {
        threads[i].join();
    }
}
