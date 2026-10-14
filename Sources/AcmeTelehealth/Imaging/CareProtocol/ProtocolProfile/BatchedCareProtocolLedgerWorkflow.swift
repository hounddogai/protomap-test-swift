import AcmePlatform
import Foundation

extension Imaging {
    /// Moves batched care protocol ledgers through their life cycle and keeps a journal of what it did.
    final class BatchedCareProtocolLedgerWorkflow {
        var store: any BatchedCareProtocolLedgerStore
        var validator: BatchedCareProtocolLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedCareProtocolLedgerEngine

        init(store: any BatchedCareProtocolLedgerStore, validator: BatchedCareProtocolLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedCareProtocolLedgerEngine) {
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
                throw Kit.Failure("batched care protocol ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCareProtocolLedgerStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care protocol ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCareProtocolLedgerStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched care protocol ledger \(code) not found")
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

    static func newBatchedCareProtocolLedgerWorkflow(_ store: any BatchedCareProtocolLedgerStore, clock: any Kit.Clocks.Clock) -> BatchedCareProtocolLedgerWorkflow {
        return BatchedCareProtocolLedgerWorkflow(
            store: store,
            validator: defaultBatchedCareProtocolLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedCareProtocolLedgerEngine()
        )
    }
}
