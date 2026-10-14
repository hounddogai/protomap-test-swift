import AcmePlatform
import Foundation

extension Imaging {
    /// Moves batched priority preferences through their life cycle and keeps a journal of what it did.
    final class BatchedPriorityPreferenceCoordinator {
        var store: any BatchedPriorityPreferenceStore
        var validator: BatchedPriorityPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedPriorityPreferenceEngine

        init(store: any BatchedPriorityPreferenceStore, validator: BatchedPriorityPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedPriorityPreferenceEngine) {
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
                throw Kit.Failure("batched priority preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedPriorityPreferenceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched priority preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedPriorityPreferenceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched priority preference \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newBatchedPriorityPreferenceCoordinator(_ store: any BatchedPriorityPreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedPriorityPreferenceCoordinator {
        return BatchedPriorityPreferenceCoordinator(
            store: store,
            validator: defaultBatchedPriorityPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedPriorityPreferenceEngine(flags)
        )
    }
}
