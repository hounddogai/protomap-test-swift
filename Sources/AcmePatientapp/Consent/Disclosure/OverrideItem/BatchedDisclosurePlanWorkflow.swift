import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched disclosure plans through their life cycle and keeps a journal of what it did.
    final class BatchedDisclosurePlanCoordinator {
        var store: any BatchedDisclosurePlanStore
        var validator: BatchedDisclosurePlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedDisclosurePlanStore, validator: BatchedDisclosurePlanValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched disclosure plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedDisclosurePlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched disclosure plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedDisclosurePlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newBatchedDisclosurePlanCoordinator(_ store: any BatchedDisclosurePlanStore, clock: any Kit.Clocks.Clock) -> BatchedDisclosurePlanCoordinator {
        return BatchedDisclosurePlanCoordinator(
            store: store,
            validator: defaultBatchedDisclosurePlanValidator(),
            clock: clock,
            journal: []
        )
    }
}
