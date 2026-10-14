import AcmePlatform
import Foundation

extension Referrals {
    /// Moves strict slot ledgers through their life cycle and keeps a journal of what it did.
    final class StrictSlotLedgerManager {
        var store: any StrictSlotLedgerStore
        var validator: StrictSlotLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictSlotLedgerEngine

        init(store: any StrictSlotLedgerStore, validator: StrictSlotLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictSlotLedgerEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict slot ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictSlotLedgerStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict slot ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictSlotLedgerStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict slot ledger \(code) not found")
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

    static func newStrictSlotLedgerManager(_ store: any StrictSlotLedgerStore, clock: any Kit.Clocks.Clock) -> StrictSlotLedgerManager {
        return StrictSlotLedgerManager(
            store: store,
            validator: defaultStrictSlotLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictSlotLedgerEngine()
        )
    }
}
