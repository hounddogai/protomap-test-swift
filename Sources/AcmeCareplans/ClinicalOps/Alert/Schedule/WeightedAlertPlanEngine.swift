import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted alert plan calculation.
    protocol WeightedAlertPlanModifier {
        func describe() -> String
        func adjust(_ item: WeightedAlertPlan, value: Double) -> Double
    }

    final class PercentWeightedAlertPlanAdjuster: WeightedAlertPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedAlertPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleWeightedAlertPlanAdjuster: WeightedAlertPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedAlertPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedAlertPlanAdjuster: WeightedAlertPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAlertPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted alert plan steps in order and keeps a trace of each.
    final class WeightedAlertPlanEngine {
        var steps: [any WeightedAlertPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAlertPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedAlertPlan) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [WeightedAlertPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedAlertPlanEngine() -> WeightedAlertPlanEngine {
        return WeightedAlertPlanEngine(
            steps: [
                PercentWeightedAlertPlanAdjuster(percent: -16.6),
                TitleWeightedAlertPlanAdjuster(factors: ["east": 1.32, "online": 1.19]),
                TieredWeightedAlertPlanAdjuster(bounds: [4004.0, 8822.0], rates: [0.93, 1.18]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 50890.9
        )
    }
}
