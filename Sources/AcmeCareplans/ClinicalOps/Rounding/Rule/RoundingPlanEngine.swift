import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding plan calculation.
    protocol RoundingPlanAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingPlan, value: Double) -> Double
    }

    final class TieredRoundingPlanAdjuster: RoundingPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRoundingPlanAdjuster: RoundingPlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRoundingPlanAdjuster: RoundingPlanAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRoundingPlanAdjuster: RoundingPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryRoundingPlanAdjuster: RoundingPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RoundingPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rounding plan steps in order and keeps a trace of each.
    final class RoundingPlanEngine {
        var steps: [any RoundingPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingPlan) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [RoundingPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingPlanEngine() -> RoundingPlanEngine {
        return RoundingPlanEngine(
            steps: [
                TieredRoundingPlanAdjuster(bounds: [2480.0, 2682.0, 9213.0], rates: [0.92, 1.15, 1.11]),
                PercentRoundingPlanAdjuster(percent: -23.4),
                CapRoundingPlanAdjuster(cap: 37235.0),
                MinimumRoundingPlanAdjuster(minimum: 19.4),
                CountryRoundingPlanAdjuster(factors: ["east": 0.94, "west": 1.33, "online": 1.35]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 73312.5
        )
    }
}
