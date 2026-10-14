import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial ledgers through their life cycle and keeps a journal of what it did.
    final class DenialLedgerCoordinator {
        var store: any DenialLedgerStore
        var validator: DenialLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DenialLedgerStore, validator: DenialLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("denial ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialLedgerStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialLedgerStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newDenialLedgerCoordinator(_ store: any DenialLedgerStore, clock: any Kit.Clocks.Clock) -> DenialLedgerCoordinator {
        return DenialLedgerCoordinator(
            store: store,
            validator: defaultDenialLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
