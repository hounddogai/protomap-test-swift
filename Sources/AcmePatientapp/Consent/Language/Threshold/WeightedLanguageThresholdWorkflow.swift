import AcmePlatform
import Foundation

extension Consent {
    /// Moves weighted language thresholds through their life cycle and keeps a journal of what it did.
    final class WeightedLanguageThresholdWorkflow {
        var store: any WeightedLanguageThresholdStore
        var validator: WeightedLanguageThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedLanguageThresholdEngine

        init(store: any WeightedLanguageThresholdStore, validator: WeightedLanguageThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedLanguageThresholdEngine) {
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
                throw Kit.Failure("weighted language threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedLanguageThresholdStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted language threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedLanguageThresholdStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted language threshold \(code) not found")
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

    static func newWeightedLanguageThresholdWorkflow(_ store: any WeightedLanguageThresholdStore, clock: any Kit.Clocks.Clock) -> WeightedLanguageThresholdWorkflow {
        return WeightedLanguageThresholdWorkflow(
            store: store,
            validator: defaultWeightedLanguageThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedLanguageThresholdEngine()
        )
    }
}
