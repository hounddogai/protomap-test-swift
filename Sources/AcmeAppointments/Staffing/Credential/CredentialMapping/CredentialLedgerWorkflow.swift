import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential ledgers through their life cycle and keeps a journal of what it did.
    final class CredentialLedgerDesk {
        var store: any CredentialLedgerStore
        var validator: CredentialLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CredentialLedgerEngine

        init(store: any CredentialLedgerStore, validator: CredentialLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CredentialLedgerEngine) {
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
                throw Kit.Failure("credential ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialLedgerStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialLedgerStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential ledger \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newCredentialLedgerDesk(_ store: any CredentialLedgerStore, clock: any Kit.Clocks.Clock) -> CredentialLedgerDesk {
        return CredentialLedgerDesk(
            store: store,
            validator: defaultCredentialLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultCredentialLedgerEngine()
        )
    }
}
