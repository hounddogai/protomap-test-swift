import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment entries through their life cycle and keeps a journal of what it did.
    final class AssessmentEntryCoordinator {
        var store: any AssessmentEntryStore
        var validator: AssessmentEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AssessmentEntryStore, validator: AssessmentEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("assessment entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentEntryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentEntryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newAssessmentEntryCoordinator(_ store: any AssessmentEntryStore, clock: any Kit.Clocks.Clock) -> AssessmentEntryCoordinator {
        return AssessmentEntryCoordinator(
            store: store,
            validator: defaultAssessmentEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
