import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched witness quotas through their life cycle and keeps a journal of what it did.
    final class BatchedWitnessQuotaWorkflow {
        var store: any BatchedWitnessQuotaStore
        var validator: BatchedWitnessQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedWitnessQuotaEngine

        init(store: any BatchedWitnessQuotaStore, validator: BatchedWitnessQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedWitnessQuotaEngine) {
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
                throw Kit.Failure("batched witness quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedWitnessQuotaStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched witness quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedWitnessQuotaStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched witness quota \(code) not found")
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

    static func newBatchedWitnessQuotaWorkflow(_ store: any BatchedWitnessQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedWitnessQuotaWorkflow {
        return BatchedWitnessQuotaWorkflow(
            store: store,
            validator: defaultBatchedWitnessQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedWitnessQuotaEngine(flags)
        )
    }
}
