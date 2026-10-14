import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory ledgers through their life cycle and keeps a journal of what it did.
    final class InventoryLedgerWorkflow {
        var store: any InventoryLedgerStore
        var validator: InventoryLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any InventoryLedgerStore, validator: InventoryLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("inventory ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryLedgerStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryLedgerStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newInventoryLedgerWorkflow(_ store: any InventoryLedgerStore, clock: any Kit.Clocks.Clock) -> InventoryLedgerWorkflow {
        return InventoryLedgerWorkflow(
            store: store,
            validator: defaultInventoryLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
