import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial plan calculation.
    protocol DenialPlanStep {
        func describe() -> String
        func adjust(_ item: DenialPlan, value: Double) -> Double
    }

    final class MinimumDenialPlanAdjuster: DenialPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDenialPlanAdjuster: DenialPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryDenialPlanAdjuster: DenialPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DenialPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the denial plan steps in order and keeps a trace of each.
    final class DenialPlanEngine {
        var steps: [any DenialPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialPlanStep = steps[index]
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

        func evaluateAll(_ items: [DenialPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialPlanEngine() -> DenialPlanEngine {
        return DenialPlanEngine(
            steps: [
                MinimumDenialPlanAdjuster(minimum: 5.0),
                TieredDenialPlanAdjuster(bounds: [7339.0, 7542.0, 8011.0], rates: [0.93, 0.94, 1.17]),
                CountryDenialPlanAdjuster(factors: ["online": 1.16, "south": 1.17, "north": 0.97]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 39149.7
        )
    }
}
