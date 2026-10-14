import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled cleaning assignments through their life cycle and keeps a journal of what it did.
    final class ScheduledCleaningAssignmentService {
        var store: any ScheduledCleaningAssignmentStore
        var validator: ScheduledCleaningAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledCleaningAssignmentStore, validator: ScheduledCleaningAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled cleaning assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCleaningAssignmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled cleaning assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCleaningAssignmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newScheduledCleaningAssignmentService(_ store: any ScheduledCleaningAssignmentStore, clock: any Kit.Clocks.Clock) -> ScheduledCleaningAssignmentService {
        return ScheduledCleaningAssignmentService(
            store: store,
            validator: defaultScheduledCleaningAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
