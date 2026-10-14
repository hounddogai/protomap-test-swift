import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched goal drafts through their life cycle and keeps a journal of what it did.
    final class BatchedGoalDraftDesk {
        var store: any BatchedGoalDraftStore
        var validator: BatchedGoalDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedGoalDraftStore, validator: BatchedGoalDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched goal draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedGoalDraftStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched goal draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedGoalDraftStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newBatchedGoalDraftDesk(_ store: any BatchedGoalDraftStore, clock: any Kit.Clocks.Clock) -> BatchedGoalDraftDesk {
        return BatchedGoalDraftDesk(
            store: store,
            validator: defaultBatchedGoalDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
