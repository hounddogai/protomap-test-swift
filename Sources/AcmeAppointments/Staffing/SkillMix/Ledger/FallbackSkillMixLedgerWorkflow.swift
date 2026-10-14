import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback skill mix ledgers through their life cycle and keeps a journal of what it did.
    final class FallbackSkillMixLedgerDesk {
        var store: any FallbackSkillMixLedgerStore
        var validator: FallbackSkillMixLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackSkillMixLedgerEngine

        init(store: any FallbackSkillMixLedgerStore, validator: FallbackSkillMixLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackSkillMixLedgerEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback skill mix ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackSkillMixLedgerStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback skill mix ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackSkillMixLedgerStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback skill mix ledger \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newFallbackSkillMixLedgerDesk(_ store: any FallbackSkillMixLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackSkillMixLedgerDesk {
        return FallbackSkillMixLedgerDesk(
            store: store,
            validator: defaultFallbackSkillMixLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackSkillMixLedgerEngine(flags)
        )
    }
}
