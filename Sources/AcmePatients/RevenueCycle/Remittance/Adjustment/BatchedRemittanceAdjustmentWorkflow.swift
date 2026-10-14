import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched remittance adjustments through their life cycle and keeps a journal of what it did.
    final class BatchedRemittanceAdjustmentDesk {
        var store: any BatchedRemittanceAdjustmentStore
        var validator: BatchedRemittanceAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedRemittanceAdjustmentStore, validator: BatchedRemittanceAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched remittance adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedRemittanceAdjustmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched remittance adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedRemittanceAdjustmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newBatchedRemittanceAdjustmentDesk(_ store: any BatchedRemittanceAdjustmentStore, clock: any Kit.Clocks.Clock) -> BatchedRemittanceAdjustmentDesk {
        return BatchedRemittanceAdjustmentDesk(
            store: store,
            validator: defaultBatchedRemittanceAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
