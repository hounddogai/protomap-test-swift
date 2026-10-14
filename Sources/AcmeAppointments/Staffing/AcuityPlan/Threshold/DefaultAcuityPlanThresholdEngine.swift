import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default acuity plan threshold calculation.
    protocol DefaultAcuityPlanThresholdModifier {
        func describe() -> String
        func adjust(_ item: DefaultAcuityPlanThreshold, value: Double) -> Double
    }

    final class LabelDefaultAcuityPlanThresholdAdjuster: DefaultAcuityPlanThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultAcuityPlanThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultAcuityPlanThresholdAdjuster: DefaultAcuityPlanThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultAcuityPlanThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultAcuityPlanThresholdAdjuster: DefaultAcuityPlanThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultAcuityPlanThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default acuity plan threshold steps in order and keeps a trace of each.
    final class DefaultAcuityPlanThresholdEngine {
        var steps: [any DefaultAcuityPlanThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAcuityPlanThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultAcuityPlanThreshold) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultAcuityPlanThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultAcuityPlanThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultAcuityPlanThresholdEngine() -> DefaultAcuityPlanThresholdEngine {
        return DefaultAcuityPlanThresholdEngine(
            steps: [
                LabelDefaultAcuityPlanThresholdAdjuster(factors: ["central": 1.29]),
                MinimumDefaultAcuityPlanThresholdAdjuster(minimum: 26.5),
                TieredDefaultAcuityPlanThresholdAdjuster(bounds: [1401.0, 2026.0], rates: [1.14, 1.08]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 65691.8
        )
    }
}
