import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness ledgers through their life cycle and keeps a journal of what it did.
    final class WitnessLedgerManager {
        var store: any WitnessLedgerStore
        var validator: WitnessLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WitnessLedgerStore, validator: WitnessLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessLedgerStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessLedgerStatus.retired)
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

    static func newWitnessLedgerManager(_ store: any WitnessLedgerStore, clock: any Kit.Clocks.Clock) -> WitnessLedgerManager {
        return WitnessLedgerManager(
            store: store,
            validator: defaultWitnessLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
