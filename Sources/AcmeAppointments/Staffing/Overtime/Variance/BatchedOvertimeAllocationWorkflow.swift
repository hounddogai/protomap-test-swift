import AcmePlatform
import Foundation

extension Staffing {
    /// Moves batched overtime allocations through their life cycle and keeps a journal of what it did.
    final class BatchedOvertimeAllocationWorkflow {
        var store: any BatchedOvertimeAllocationStore
        var validator: BatchedOvertimeAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedOvertimeAllocationStore, validator: BatchedOvertimeAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched overtime allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedOvertimeAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched overtime allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedOvertimeAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newBatchedOvertimeAllocationWorkflow(_ store: any BatchedOvertimeAllocationStore, clock: any Kit.Clocks.Clock) -> BatchedOvertimeAllocationWorkflow {
        return BatchedOvertimeAllocationWorkflow(
            store: store,
            validator: defaultBatchedOvertimeAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
