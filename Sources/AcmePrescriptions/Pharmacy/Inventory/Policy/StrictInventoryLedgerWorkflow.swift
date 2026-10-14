import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves strict inventory ledgers through their life cycle and keeps a journal of what it did.
    final class StrictInventoryLedgerService {
        var store: any StrictInventoryLedgerStore
        var validator: StrictInventoryLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictInventoryLedgerEngine

        init(store: any StrictInventoryLedgerStore, validator: StrictInventoryLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictInventoryLedgerEngine) {
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
                throw Kit.Failure("strict inventory ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictInventoryLedgerStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict inventory ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictInventoryLedgerStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict inventory ledger \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newStrictInventoryLedgerService(_ store: any StrictInventoryLedgerStore, clock: any Kit.Clocks.Clock) -> StrictInventoryLedgerService {
        return StrictInventoryLedgerService(
            store: store,
            validator: defaultStrictInventoryLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictInventoryLedgerEngine()
        )
    }
}
