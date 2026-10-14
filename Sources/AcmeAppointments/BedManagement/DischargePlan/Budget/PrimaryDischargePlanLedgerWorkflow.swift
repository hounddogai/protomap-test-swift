import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary discharge plan ledgers through their life cycle and keeps a journal of what it did.
    final class PrimaryDischargePlanLedgerManager {
        var store: any PrimaryDischargePlanLedgerStore
        var validator: PrimaryDischargePlanLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryDischargePlanLedgerEngine

        init(store: any PrimaryDischargePlanLedgerStore, validator: PrimaryDischargePlanLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryDischargePlanLedgerEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryDischargePlanLedgerStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryDischargePlanLedgerStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan ledger \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryDischargePlanLedgerManager(_ store: any PrimaryDischargePlanLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryDischargePlanLedgerManager {
        return PrimaryDischargePlanLedgerManager(
            store: store,
            validator: defaultPrimaryDischargePlanLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryDischargePlanLedgerEngine(flags)
        )
    }
}
