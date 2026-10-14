import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves primary rounding profiles through their life cycle and keeps a journal of what it did.
    final class PrimaryRoundingProfileCoordinator {
        var store: any PrimaryRoundingProfileStore
        var validator: PrimaryRoundingProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryRoundingProfileStore, validator: PrimaryRoundingProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary rounding profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryRoundingProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary rounding profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryRoundingProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newPrimaryRoundingProfileCoordinator(_ store: any PrimaryRoundingProfileStore, clock: any Kit.Clocks.Clock) -> PrimaryRoundingProfileCoordinator {
        return PrimaryRoundingProfileCoordinator(
            store: store,
            validator: defaultPrimaryRoundingProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
