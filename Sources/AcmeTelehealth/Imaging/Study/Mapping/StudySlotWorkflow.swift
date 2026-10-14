import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study slots through their life cycle and keeps a journal of what it did.
    final class StudySlotManager {
        var store: any StudySlotStore
        var validator: StudySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StudySlotStore, validator: StudySlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("study slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudySlotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudySlotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newStudySlotManager(_ store: any StudySlotStore, clock: any Kit.Clocks.Clock) -> StudySlotManager {
        return StudySlotManager(store: store, validator: defaultStudySlotValidator(), clock: clock, journal: [])
    }
}
