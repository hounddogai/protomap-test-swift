import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment schedules through their life cycle and keeps a journal of what it did.
    final class AssessmentScheduleDesk {
        var store: any AssessmentScheduleStore
        var validator: AssessmentScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AssessmentScheduleStore, validator: AssessmentScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("assessment schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentScheduleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentScheduleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newAssessmentScheduleDesk(_ store: any AssessmentScheduleStore, clock: any Kit.Clocks.Clock) -> AssessmentScheduleDesk {
        return AssessmentScheduleDesk(
            store: store,
            validator: defaultAssessmentScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
