import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched statement bundles through their life cycle and keeps a journal of what it did.
    final class BatchedStatementBundleWorkflow {
        var store: any BatchedStatementBundleStore
        var validator: BatchedStatementBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedStatementBundleEngine

        init(store: any BatchedStatementBundleStore, validator: BatchedStatementBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedStatementBundleEngine) {
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
                throw Kit.Failure("batched statement bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedStatementBundleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched statement bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedStatementBundleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched statement bundle \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newBatchedStatementBundleWorkflow(_ store: any BatchedStatementBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedStatementBundleWorkflow {
        return BatchedStatementBundleWorkflow(
            store: store,
            validator: defaultBatchedStatementBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedStatementBundleEngine(flags)
        )
    }
}
