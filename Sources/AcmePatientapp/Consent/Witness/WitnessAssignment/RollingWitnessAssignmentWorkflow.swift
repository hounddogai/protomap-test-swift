import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling witness assignments through their life cycle and keeps a journal of what it did.
    final class RollingWitnessAssignmentCoordinator {
        var store: any RollingWitnessAssignmentStore
        var validator: RollingWitnessAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingWitnessAssignmentStore, validator: RollingWitnessAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling witness assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingWitnessAssignmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling witness assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingWitnessAssignmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRollingWitnessAssignmentCoordinator(_ store: any RollingWitnessAssignmentStore, clock: any Kit.Clocks.Clock) -> RollingWitnessAssignmentCoordinator {
        return RollingWitnessAssignmentCoordinator(
            store: store,
            validator: defaultRollingWitnessAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
