import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves default charge ledgers through their life cycle and keeps a journal of what it did.
    final class DefaultChargeLedgerWorkflow {
        var store: any DefaultChargeLedgerStore
        var validator: DefaultChargeLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultChargeLedgerEngine

        init(store: any DefaultChargeLedgerStore, validator: DefaultChargeLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultChargeLedgerEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default charge ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultChargeLedgerStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default charge ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultChargeLedgerStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default charge ledger \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newDefaultChargeLedgerWorkflow(_ store: any DefaultChargeLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultChargeLedgerWorkflow {
        return DefaultChargeLedgerWorkflow(
            store: store,
            validator: defaultDefaultChargeLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultChargeLedgerEngine(flags)
        )
    }
}
