import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim ledgers through their life cycle and keeps a journal of what it did.
    final class ClaimLedgerWorkflow {
        var store: any ClaimLedgerStore
        var validator: ClaimLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimLedgerEngine

        init(store: any ClaimLedgerStore, validator: ClaimLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimLedgerEngine) {
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
                throw Kit.Failure("claim ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimLedgerStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimLedgerStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim ledger \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newClaimLedgerWorkflow(_ store: any ClaimLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClaimLedgerWorkflow {
        return ClaimLedgerWorkflow(
            store: store,
            validator: defaultClaimLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimLedgerEngine(flags)
        )
    }
}
