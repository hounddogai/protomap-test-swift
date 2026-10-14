import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel ledgers through their life cycle and keeps a journal of what it did.
    final class PanelLedgerDesk {
        var store: any PanelLedgerStore
        var validator: PanelLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PanelLedgerStore, validator: PanelLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("panel ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelLedgerStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelLedgerStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newPanelLedgerDesk(_ store: any PanelLedgerStore, clock: any Kit.Clocks.Clock) -> PanelLedgerDesk {
        return PanelLedgerDesk(store: store, validator: defaultPanelLedgerValidator(), clock: clock, journal: [])
    }
}
