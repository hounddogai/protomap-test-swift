import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure assignments through their life cycle and keeps a journal of what it did.
    final class ClosureAssignmentWorkflow {
        var store: any ClosureAssignmentStore
        var validator: ClosureAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClosureAssignmentStore, validator: ClosureAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureAssignmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureAssignmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newClosureAssignmentWorkflow(_ store: any ClosureAssignmentStore, clock: any Kit.Clocks.Clock) -> ClosureAssignmentWorkflow {
        return ClosureAssignmentWorkflow(
            store: store,
            validator: defaultClosureAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
