import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves tiered substitution profiles through their life cycle and keeps a journal of what it did.
    final class TieredSubstitutionProfileDesk {
        var store: any TieredSubstitutionProfileStore
        var validator: TieredSubstitutionProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredSubstitutionProfileStore, validator: TieredSubstitutionProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered substitution profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredSubstitutionProfileStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered substitution profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredSubstitutionProfileStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newTieredSubstitutionProfileDesk(_ store: any TieredSubstitutionProfileStore, clock: any Kit.Clocks.Clock) -> TieredSubstitutionProfileDesk {
        return TieredSubstitutionProfileDesk(
            store: store,
            validator: defaultTieredSubstitutionProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
