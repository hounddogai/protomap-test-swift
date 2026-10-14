import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves strict assessment entries through their life cycle and keeps a journal of what it did.
    final class StrictAssessmentEntryManager {
        var store: any StrictAssessmentEntryStore
        var validator: StrictAssessmentEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictAssessmentEntryStore, validator: StrictAssessmentEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict assessment entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAssessmentEntryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAssessmentEntryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newStrictAssessmentEntryManager(_ store: any StrictAssessmentEntryStore, clock: any Kit.Clocks.Clock) -> StrictAssessmentEntryManager {
        return StrictAssessmentEntryManager(
            store: store,
            validator: defaultStrictAssessmentEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
