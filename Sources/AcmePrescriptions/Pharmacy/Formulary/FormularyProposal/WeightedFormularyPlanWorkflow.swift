import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted formulary plans through their life cycle and keeps a journal of what it did.
    final class WeightedFormularyPlanWorkflow {
        var store: any WeightedFormularyPlanStore
        var validator: WeightedFormularyPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedFormularyPlanEngine

        init(store: any WeightedFormularyPlanStore, validator: WeightedFormularyPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedFormularyPlanEngine) {
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
                throw Kit.Failure("weighted formulary plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedFormularyPlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedFormularyPlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary plan \(code) not found")
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

    static func newWeightedFormularyPlanWorkflow(_ store: any WeightedFormularyPlanStore, clock: any Kit.Clocks.Clock) -> WeightedFormularyPlanWorkflow {
        return WeightedFormularyPlanWorkflow(
            store: store,
            validator: defaultWeightedFormularyPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedFormularyPlanEngine()
        )
    }
}
