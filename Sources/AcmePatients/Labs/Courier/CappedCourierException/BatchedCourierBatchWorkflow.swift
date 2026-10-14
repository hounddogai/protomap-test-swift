import AcmePlatform
import Foundation

extension Labs {
    /// Moves batched courier batches through their life cycle and keeps a journal of what it did.
    final class BatchedCourierBatchWorkflow {
        var store: any BatchedCourierBatchStore
        var validator: BatchedCourierBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedCourierBatchEngine

        init(store: any BatchedCourierBatchStore, validator: BatchedCourierBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedCourierBatchEngine) {
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
                throw Kit.Failure("batched courier batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCourierBatchStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched courier batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCourierBatchStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched courier batch \(code) not found")
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

    static func newBatchedCourierBatchWorkflow(_ store: any BatchedCourierBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedCourierBatchWorkflow {
        return BatchedCourierBatchWorkflow(
            store: store,
            validator: defaultBatchedCourierBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedCourierBatchEngine(flags)
        )
    }
}
