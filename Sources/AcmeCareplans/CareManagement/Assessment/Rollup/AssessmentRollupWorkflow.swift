import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment rollups through their life cycle and keeps a journal of what it did.
    final class AssessmentRollupWorkflow {
        var store: any AssessmentRollupStore
        var validator: AssessmentRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AssessmentRollupStore, validator: AssessmentRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("assessment rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentRollupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAssessmentRollupWorkflow(_ store: any AssessmentRollupStore, clock: any Kit.Clocks.Clock) -> AssessmentRollupWorkflow {
        return AssessmentRollupWorkflow(
            store: store,
            validator: defaultAssessmentRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
