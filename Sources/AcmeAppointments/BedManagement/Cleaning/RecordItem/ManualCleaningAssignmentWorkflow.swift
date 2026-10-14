import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves manual cleaning assignments through their life cycle and keeps a journal of what it did.
    final class ManualCleaningAssignmentCoordinator {
        var store: any ManualCleaningAssignmentStore
        var validator: ManualCleaningAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualCleaningAssignmentStore, validator: ManualCleaningAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual cleaning assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualCleaningAssignmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual cleaning assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualCleaningAssignmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newManualCleaningAssignmentCoordinator(_ store: any ManualCleaningAssignmentStore, clock: any Kit.Clocks.Clock) -> ManualCleaningAssignmentCoordinator {
        return ManualCleaningAssignmentCoordinator(
            store: store,
            validator: defaultManualCleaningAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
