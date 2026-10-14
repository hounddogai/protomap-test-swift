import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves batched order set exceptions through their life cycle and keeps a journal of what it did.
    final class BatchedOrderSetExceptionDesk {
        var store: any BatchedOrderSetExceptionStore
        var validator: BatchedOrderSetExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedOrderSetExceptionEngine

        init(store: any BatchedOrderSetExceptionStore, validator: BatchedOrderSetExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedOrderSetExceptionEngine) {
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
                throw Kit.Failure("batched order set exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedOrderSetExceptionStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched order set exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedOrderSetExceptionStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched order set exception \(code) not found")
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

    static func newBatchedOrderSetExceptionDesk(_ store: any BatchedOrderSetExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedOrderSetExceptionDesk {
        return BatchedOrderSetExceptionDesk(
            store: store,
            validator: defaultBatchedOrderSetExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedOrderSetExceptionEngine(flags)
        )
    }
}
