import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled denial budget calculation.
    protocol ScheduledDenialBudgetStep {
        func describe() -> String
        func adjust(_ item: ScheduledDenialBudget, value: Double) -> Double
    }

    final class RoundingScheduledDenialBudgetAdjuster: ScheduledDenialBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledDenialBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredScheduledDenialBudgetAdjuster: ScheduledDenialBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledDenialBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledDenialBudgetThresholdOffsetAdjuster: ScheduledDenialBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ScheduledDenialBudget, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumScheduledDenialBudgetAdjuster: ScheduledDenialBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledDenialBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledDenialBudgetAdjuster: ScheduledDenialBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledDenialBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled denial budget steps in order and keeps a trace of each.
    final class ScheduledDenialBudgetEngine {
        var steps: [any ScheduledDenialBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledDenialBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledDenialBudget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledDenialBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledDenialBudgetEngine() -> ScheduledDenialBudgetEngine {
        return ScheduledDenialBudgetEngine(
            steps: [
                RoundingScheduledDenialBudgetAdjuster(step: 0.05),
                TieredScheduledDenialBudgetAdjuster(bounds: [1537.0, 6583.0, 7756.0], rates: [0.99, 0.95, 1.11]),
                ScheduledDenialBudgetThresholdOffsetAdjuster(weight: 0.64),
                MinimumScheduledDenialBudgetAdjuster(minimum: 24.2),
                CapScheduledDenialBudgetAdjuster(cap: 32930.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 84228.7
        )
    }
}
