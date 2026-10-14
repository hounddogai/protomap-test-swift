import AcmePlatform
import Foundation

extension Consent {
    /// Moves batched language thresholds through their life cycle and keeps a journal of what it did.
    final class BatchedLanguageThresholdWorkflow {
        var store: any BatchedLanguageThresholdStore
        var validator: BatchedLanguageThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedLanguageThresholdEngine

        init(store: any BatchedLanguageThresholdStore, validator: BatchedLanguageThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedLanguageThresholdEngine) {
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
                throw Kit.Failure("batched language threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedLanguageThresholdStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched language threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedLanguageThresholdStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched language threshold \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newBatchedLanguageThresholdWorkflow(_ store: any BatchedLanguageThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BatchedLanguageThresholdWorkflow {
        return BatchedLanguageThresholdWorkflow(
            store: store,
            validator: defaultBatchedLanguageThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedLanguageThresholdEngine(flags)
        )
    }
}
