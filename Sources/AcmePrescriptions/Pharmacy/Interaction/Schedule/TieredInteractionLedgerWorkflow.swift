import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves tiered interaction ledgers through their life cycle and keeps a journal of what it did.
    final class TieredInteractionLedgerCoordinator {
        var store: any TieredInteractionLedgerStore
        var validator: TieredInteractionLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredInteractionLedgerEngine

        init(store: any TieredInteractionLedgerStore, validator: TieredInteractionLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredInteractionLedgerEngine) {
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
                throw Kit.Failure("tiered interaction ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredInteractionLedgerStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered interaction ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredInteractionLedgerStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered interaction ledger \(code) not found")
            }
            let result = engine.price(item)
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

    static func newTieredInteractionLedgerCoordinator(_ store: any TieredInteractionLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredInteractionLedgerCoordinator {
        return TieredInteractionLedgerCoordinator(
            store: store,
            validator: defaultTieredInteractionLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredInteractionLedgerEngine(flags)
        )
    }
}
