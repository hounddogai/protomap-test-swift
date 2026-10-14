import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan budget calculation.
    protocol AcuityPlanBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanBudget, value: Double) -> Double
    }

    final class FlaggedAcuityPlanBudgetAdjuster: AcuityPlanBudgetAdjuster {
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

        func adjust(_ item: AcuityPlanBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAcuityPlanBudgetAdjuster: AcuityPlanBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameAcuityPlanBudgetAdjuster: AcuityPlanBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AcuityPlanBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAcuityPlanBudgetAdjuster: AcuityPlanBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the acuity plan budget steps in order and keeps a trace of each.
    final class AcuityPlanBudgetEngine {
        var steps: [any AcuityPlanBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanBudget) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [AcuityPlanBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanBudgetEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanBudgetEngine {
        return AcuityPlanBudgetEngine(
            steps: [
                FlaggedAcuityPlanBudgetAdjuster(flags: flags, flag: "acuity-plan-budget-batched", percent: 8.6),
                TieredAcuityPlanBudgetAdjuster(bounds: [161.0, 3871.0], rates: [0.83, 0.95]),
                NameAcuityPlanBudgetAdjuster(factors: ["north": 0.81]),
                PercentAcuityPlanBudgetAdjuster(percent: 9.5),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 69120.5
        )
    }
}
