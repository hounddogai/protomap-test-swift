import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched goal baselines through their life cycle and keeps a journal of what it did.
    final class BatchedGoalBaselineManager {
        var store: any BatchedGoalBaselineStore
        var validator: BatchedGoalBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedGoalBaselineStore, validator: BatchedGoalBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched goal baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedGoalBaselineStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched goal baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedGoalBaselineStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newBatchedGoalBaselineManager(_ store: any BatchedGoalBaselineStore, clock: any Kit.Clocks.Clock) -> BatchedGoalBaselineManager {
        return BatchedGoalBaselineManager(
            store: store,
            validator: defaultBatchedGoalBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
