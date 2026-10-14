import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the primary remittance plan calculation.
    protocol PrimaryRemittancePlanStep {
        func describe() -> String
        func adjust(_ item: PrimaryRemittancePlan, value: Double) -> Double
    }

    final class PercentPrimaryRemittancePlanAdjuster: PrimaryRemittancePlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryRemittancePlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryRemittancePlanAdjuster: PrimaryRemittancePlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryRemittancePlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryRemittancePlanAdjuster: PrimaryRemittancePlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryRemittancePlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary remittance plan steps in order and keeps a trace of each.
    final class PrimaryRemittancePlanEngine {
        var steps: [any PrimaryRemittancePlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryRemittancePlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryRemittancePlan) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryRemittancePlanStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryRemittancePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryRemittancePlanEngine() -> PrimaryRemittancePlanEngine {
        return PrimaryRemittancePlanEngine(
            steps: [
                PercentPrimaryRemittancePlanAdjuster(percent: 20.5),
                MinimumPrimaryRemittancePlanAdjuster(minimum: 17.0),
                TieredPrimaryRemittancePlanAdjuster(bounds: [4254.0, 8460.0], rates: [1.1, 1.18]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 1954.0
        )
    }
}
