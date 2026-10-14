import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted discharge plan metrics through their life cycle and keeps a journal of what it did.
    final class WeightedDischargePlanMetricWorkflow {
        var store: any WeightedDischargePlanMetricStore
        var validator: WeightedDischargePlanMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedDischargePlanMetricEngine

        init(store: any WeightedDischargePlanMetricStore, validator: WeightedDischargePlanMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedDischargePlanMetricEngine) {
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
                throw Kit.Failure("weighted discharge plan metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedDischargePlanMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted discharge plan metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedDischargePlanMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted discharge plan metric \(code) not found")
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

    static func newWeightedDischargePlanMetricWorkflow(_ store: any WeightedDischargePlanMetricStore, clock: any Kit.Clocks.Clock) -> WeightedDischargePlanMetricWorkflow {
        return WeightedDischargePlanMetricWorkflow(
            store: store,
            validator: defaultWeightedDischargePlanMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedDischargePlanMetricEngine()
        )
    }
}
