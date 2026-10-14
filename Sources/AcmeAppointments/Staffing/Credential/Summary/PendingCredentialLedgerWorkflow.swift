import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending credential ledgers through their life cycle and keeps a journal of what it did.
    final class PendingCredentialLedgerDesk {
        var store: any PendingCredentialLedgerStore
        var validator: PendingCredentialLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingCredentialLedgerEngine

        init(store: any PendingCredentialLedgerStore, validator: PendingCredentialLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingCredentialLedgerEngine) {
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
                throw Kit.Failure("pending credential ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCredentialLedgerStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending credential ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCredentialLedgerStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending credential ledger \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newPendingCredentialLedgerDesk(_ store: any PendingCredentialLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingCredentialLedgerDesk {
        return PendingCredentialLedgerDesk(
            store: store,
            validator: defaultPendingCredentialLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingCredentialLedgerEngine(flags)
        )
    }
}
