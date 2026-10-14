import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves batched bed board ledgers through their life cycle and keeps a journal of what it did.
    final class BatchedBedBoardLedgerWorkflow {
        var store: any BatchedBedBoardLedgerStore
        var validator: BatchedBedBoardLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedBedBoardLedgerEngine

        init(store: any BatchedBedBoardLedgerStore, validator: BatchedBedBoardLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedBedBoardLedgerEngine) {
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
                throw Kit.Failure("batched bed board ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedBedBoardLedgerStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched bed board ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedBedBoardLedgerStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched bed board ledger \(code) not found")
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

    static func newBatchedBedBoardLedgerWorkflow(_ store: any BatchedBedBoardLedgerStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedBedBoardLedgerWorkflow {
        return BatchedBedBoardLedgerWorkflow(
            store: store,
            validator: defaultBatchedBedBoardLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedBedBoardLedgerEngine(flags)
        )
    }
}
