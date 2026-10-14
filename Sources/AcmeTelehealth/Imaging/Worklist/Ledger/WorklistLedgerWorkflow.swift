import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist ledgers through their life cycle and keeps a journal of what it did.
    final class WorklistLedgerManager {
        var store: any WorklistLedgerStore
        var validator: WorklistLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistLedgerEngine

        init(store: any WorklistLedgerStore, validator: WorklistLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistLedgerEngine) {
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
                throw Kit.Failure("worklist ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistLedgerStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistLedgerStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist ledger \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newWorklistLedgerManager(_ store: any WorklistLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistLedgerManager {
        return WorklistLedgerManager(
            store: store,
            validator: defaultWorklistLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistLedgerEngine(flags)
        )
    }
}
