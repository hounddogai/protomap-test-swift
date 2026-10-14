import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered read ledgers through their life cycle and keeps a journal of what it did.
    final class TieredReadLedgerService {
        var store: any TieredReadLedgerStore
        var validator: TieredReadLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredReadLedgerEngine

        init(store: any TieredReadLedgerStore, validator: TieredReadLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredReadLedgerEngine) {
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
                throw Kit.Failure("tiered read ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredReadLedgerStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered read ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredReadLedgerStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered read ledger \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newTieredReadLedgerService(_ store: any TieredReadLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredReadLedgerService {
        return TieredReadLedgerService(
            store: store,
            validator: defaultTieredReadLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredReadLedgerEngine(flags)
        )
    }
}
