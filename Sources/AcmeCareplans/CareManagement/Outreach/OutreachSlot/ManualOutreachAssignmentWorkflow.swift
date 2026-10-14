import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual outreach assignments through their life cycle and keeps a journal of what it did.
    final class ManualOutreachAssignmentCoordinator {
        var store: any ManualOutreachAssignmentStore
        var validator: ManualOutreachAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualOutreachAssignmentStore, validator: ManualOutreachAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual outreach assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualOutreachAssignmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual outreach assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualOutreachAssignmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newManualOutreachAssignmentCoordinator(_ store: any ManualOutreachAssignmentStore, clock: any Kit.Clocks.Clock) -> ManualOutreachAssignmentCoordinator {
        return ManualOutreachAssignmentCoordinator(
            store: store,
            validator: defaultManualOutreachAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
