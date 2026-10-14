import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling cleaning assignments through their life cycle and keeps a journal of what it did.
    final class RollingCleaningAssignmentWorkflow {
        var store: any RollingCleaningAssignmentStore
        var validator: RollingCleaningAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingCleaningAssignmentStore, validator: RollingCleaningAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling cleaning assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCleaningAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling cleaning assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCleaningAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newRollingCleaningAssignmentWorkflow(_ store: any RollingCleaningAssignmentStore, clock: any Kit.Clocks.Clock) -> RollingCleaningAssignmentWorkflow {
        return RollingCleaningAssignmentWorkflow(
            store: store,
            validator: defaultRollingCleaningAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
