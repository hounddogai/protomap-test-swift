import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves batched statement groups through their life cycle and keeps a journal of what it did.
    final class BatchedStatementGroupDesk {
        var store: any BatchedStatementGroupStore
        var validator: BatchedStatementGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedStatementGroupEngine

        init(store: any BatchedStatementGroupStore, validator: BatchedStatementGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedStatementGroupEngine) {
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
                throw Kit.Failure("batched statement group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedStatementGroupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched statement group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedStatementGroupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched statement group \(code) not found")
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

    static func newBatchedStatementGroupDesk(_ store: any BatchedStatementGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedStatementGroupDesk {
        return BatchedStatementGroupDesk(
            store: store,
            validator: defaultBatchedStatementGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedStatementGroupEngine(flags)
        )
    }
}
