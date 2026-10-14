import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves primary substitution assignments through their life cycle and keeps a journal of what it did.
    final class PrimarySubstitutionAssignmentCoordinator {
        var store: any PrimarySubstitutionAssignmentStore
        var validator: PrimarySubstitutionAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimarySubstitutionAssignmentStore, validator: PrimarySubstitutionAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary substitution assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimarySubstitutionAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimarySubstitutionAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimarySubstitutionAssignmentCoordinator(_ store: any PrimarySubstitutionAssignmentStore, clock: any Kit.Clocks.Clock) -> PrimarySubstitutionAssignmentCoordinator {
        return PrimarySubstitutionAssignmentCoordinator(
            store: store,
            validator: defaultPrimarySubstitutionAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
