import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves batched interaction milestones through their life cycle and keeps a journal of what it did.
    final class BatchedInteractionMilestoneCoordinator {
        var store: any BatchedInteractionMilestoneStore
        var validator: BatchedInteractionMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedInteractionMilestoneStore, validator: BatchedInteractionMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched interaction milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedInteractionMilestoneStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched interaction milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedInteractionMilestoneStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newBatchedInteractionMilestoneCoordinator(_ store: any BatchedInteractionMilestoneStore, clock: any Kit.Clocks.Clock) -> BatchedInteractionMilestoneCoordinator {
        return BatchedInteractionMilestoneCoordinator(
            store: store,
            validator: defaultBatchedInteractionMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
