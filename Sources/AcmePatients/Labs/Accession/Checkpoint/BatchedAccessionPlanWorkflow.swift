import AcmePlatform
import Foundation

extension Labs {
    /// Moves batched accession plans through their life cycle and keeps a journal of what it did.
    final class BatchedAccessionPlanManager {
        var store: any BatchedAccessionPlanStore
        var validator: BatchedAccessionPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedAccessionPlanEngine

        init(store: any BatchedAccessionPlanStore, validator: BatchedAccessionPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedAccessionPlanEngine) {
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
                throw Kit.Failure("batched accession plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedAccessionPlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched accession plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedAccessionPlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched accession plan \(code) not found")
            }
            let result = engine.run(item)
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

    static func newBatchedAccessionPlanManager(_ store: any BatchedAccessionPlanStore, clock: any Kit.Clocks.Clock) -> BatchedAccessionPlanManager {
        return BatchedAccessionPlanManager(
            store: store,
            validator: defaultBatchedAccessionPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedAccessionPlanEngine()
        )
    }
}
