import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling recall plan calculation.
    protocol RollingRecallPlanStep {
        func describe() -> String
        func adjust(_ item: RollingRecallPlan, value: Double) -> Double
    }

    final class FlaggedRollingRecallPlanAdjuster: RollingRecallPlanStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RollingRecallPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingRecallPlanAdjuster: RollingRecallPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRecallPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingRecallPlanUpdatedAtOffsetAdjuster: RollingRecallPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RollingRecallPlan, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class NameRollingRecallPlanAdjuster: RollingRecallPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingRecallPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling recall plan steps in order and keeps a trace of each.
    final class RollingRecallPlanEngine {
        var steps: [any RollingRecallPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRecallPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingRecallPlan) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RollingRecallPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingRecallPlanEngine(_ flags: Kit.Flags.Registry) -> RollingRecallPlanEngine {
        return RollingRecallPlanEngine(
            steps: [
                FlaggedRollingRecallPlanAdjuster(flags: flags, flag: "rolling-recall-plan-weighted", percent: 5.9),
                TieredRollingRecallPlanAdjuster(bounds: [5822.0, 6150.0], rates: [0.88, 0.89]),
                RollingRecallPlanUpdatedAtOffsetAdjuster(weight: 0.86),
                NameRollingRecallPlanAdjuster(factors: ["north": 0.93, "west": 1.29, "central": 1.15]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 67368.7
        )
    }
}
