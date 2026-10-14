import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback result ledgers through their life cycle and keeps a journal of what it did.
    final class FallbackResultLedgerManager {
        var store: any FallbackResultLedgerStore
        var validator: FallbackResultLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackResultLedgerEngine

        init(store: any FallbackResultLedgerStore, validator: FallbackResultLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackResultLedgerEngine) {
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
                throw Kit.Failure("fallback result ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackResultLedgerStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback result ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackResultLedgerStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback result ledger \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFallbackResultLedgerManager(_ store: any FallbackResultLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackResultLedgerManager {
        return FallbackResultLedgerManager(
            store: store,
            validator: defaultFallbackResultLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackResultLedgerEngine(flags)
        )
    }
}
