import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves regional cleaning ledgers through their life cycle and keeps a journal of what it did.
    final class RegionalCleaningLedgerService {
        var store: any RegionalCleaningLedgerStore
        var validator: RegionalCleaningLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalCleaningLedgerEngine

        init(store: any RegionalCleaningLedgerStore, validator: RegionalCleaningLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalCleaningLedgerEngine) {
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
                throw Kit.Failure("regional cleaning ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalCleaningLedgerStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional cleaning ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalCleaningLedgerStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional cleaning ledger \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRegionalCleaningLedgerService(_ store: any RegionalCleaningLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalCleaningLedgerService {
        return RegionalCleaningLedgerService(
            store: store,
            validator: defaultRegionalCleaningLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalCleaningLedgerEngine(flags)
        )
    }
}
