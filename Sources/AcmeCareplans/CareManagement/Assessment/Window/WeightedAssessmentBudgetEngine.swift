import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted assessment budget calculation.
    protocol WeightedAssessmentBudgetModifier {
        func describe() -> String
        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double
    }

    final class TieredWeightedAssessmentBudgetAdjuster: WeightedAssessmentBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedAssessmentBudgetAdjuster: WeightedAssessmentBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedAssessmentBudgetAdjuster: WeightedAssessmentBudgetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleWeightedAssessmentBudgetAdjuster: WeightedAssessmentBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWeightedAssessmentBudgetAdjuster: WeightedAssessmentBudgetModifier {
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

        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedAssessmentBudgetRateOffsetAdjuster: WeightedAssessmentBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: WeightedAssessmentBudget, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the weighted assessment budget steps in order and keeps a trace of each.
    final class WeightedAssessmentBudgetEngine {
        var steps: [any WeightedAssessmentBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAssessmentBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedAssessmentBudget) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedAssessmentBudgetModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WeightedAssessmentBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedAssessmentBudgetEngine(_ flags: Kit.Flags.Registry) -> WeightedAssessmentBudgetEngine {
        return WeightedAssessmentBudgetEngine(
            steps: [
                TieredWeightedAssessmentBudgetAdjuster(
                    bounds: [678.0, 2626.0, 6075.0, 6285.0],
                    rates: [0.95, 1.03, 0.83, 1.18]
                ),
                CapWeightedAssessmentBudgetAdjuster(cap: 7503.0),
                RoundingWeightedAssessmentBudgetAdjuster(step: 0.05),
                TitleWeightedAssessmentBudgetAdjuster(factors: ["central": 0.87, "retail": 0.87]),
                FlaggedWeightedAssessmentBudgetAdjuster(
                    flags: flags,
                    flag: "weighted-assessment-budget-regional",
                    percent: 0.6
                ),
                WeightedAssessmentBudgetRateOffsetAdjuster(weight: 1.67),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 91472.6
        )
    }
}
