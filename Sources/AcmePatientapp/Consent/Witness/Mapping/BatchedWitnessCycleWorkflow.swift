import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched witness cycles through their life cycle and keeps a journal of what it did.
    final class BatchedWitnessCycleWorkflow {
        var store: any BatchedWitnessCycleStore
        var validator: BatchedWitnessCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedWitnessCycleStore, validator: BatchedWitnessCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched witness cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedWitnessCycleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched witness cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedWitnessCycleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newBatchedWitnessCycleWorkflow(_ store: any BatchedWitnessCycleStore, clock: any Kit.Clocks.Clock) -> BatchedWitnessCycleWorkflow {
        return BatchedWitnessCycleWorkflow(
            store: store,
            validator: defaultBatchedWitnessCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
