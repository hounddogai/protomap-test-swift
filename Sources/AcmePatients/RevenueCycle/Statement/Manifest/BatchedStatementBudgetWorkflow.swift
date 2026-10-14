import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched statement budgets through their life cycle and keeps a journal of what it did.
    final class BatchedStatementBudgetCoordinator {
        var store: any BatchedStatementBudgetStore
        var validator: BatchedStatementBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedStatementBudgetEngine

        init(store: any BatchedStatementBudgetStore, validator: BatchedStatementBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedStatementBudgetEngine) {
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
                throw Kit.Failure("batched statement budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedStatementBudgetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched statement budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedStatementBudgetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched statement budget \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newBatchedStatementBudgetCoordinator(_ store: any BatchedStatementBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedStatementBudgetCoordinator {
        return BatchedStatementBudgetCoordinator(
            store: store,
            validator: defaultBatchedStatementBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedStatementBudgetEngine(flags)
        )
    }
}
