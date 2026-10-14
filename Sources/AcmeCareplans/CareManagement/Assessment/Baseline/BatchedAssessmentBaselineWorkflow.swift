import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched assessment baselines through their life cycle and keeps a journal of what it did.
    final class BatchedAssessmentBaselineDesk {
        var store: any BatchedAssessmentBaselineStore
        var validator: BatchedAssessmentBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedAssessmentBaselineStore, validator: BatchedAssessmentBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("batched assessment baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedAssessmentBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched assessment baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedAssessmentBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newBatchedAssessmentBaselineDesk(_ store: any BatchedAssessmentBaselineStore, clock: any Kit.Clocks.Clock) -> BatchedAssessmentBaselineDesk {
        return BatchedAssessmentBaselineDesk(
            store: store,
            validator: defaultBatchedAssessmentBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
