import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy interaction tiers through their life cycle and keeps a journal of what it did.
    final class LegacyInteractionTierService {
        var store: any LegacyInteractionTierStore
        var validator: LegacyInteractionTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyInteractionTierStore, validator: LegacyInteractionTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy interaction tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyInteractionTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy interaction tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyInteractionTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newLegacyInteractionTierService(_ store: any LegacyInteractionTierStore, clock: any Kit.Clocks.Clock) -> LegacyInteractionTierService {
        return LegacyInteractionTierService(
            store: store,
            validator: defaultLegacyInteractionTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
