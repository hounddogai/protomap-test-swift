import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure budget calculation.
    protocol DisclosureBudgetStep {
        func describe() -> String
        func adjust(_ item: DisclosureBudget, value: Double) -> Double
    }

    final class MinimumDisclosureBudgetAdjuster: DisclosureBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDisclosureBudgetAdjuster: DisclosureBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDisclosureBudgetAdjuster: DisclosureBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryDisclosureBudgetAdjuster: DisclosureBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DisclosureBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDisclosureBudgetAdjuster: DisclosureBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure budget steps in order and keeps a trace of each.
    final class DisclosureBudgetEngine {
        var steps: [any DisclosureBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureBudget) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureBudgetStep = steps[index]
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

        func evaluateAll(_ items: [DisclosureBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureBudgetEngine() -> DisclosureBudgetEngine {
        return DisclosureBudgetEngine(
            steps: [
                MinimumDisclosureBudgetAdjuster(minimum: 43.8),
                CapDisclosureBudgetAdjuster(cap: 22803.0),
                RoundingDisclosureBudgetAdjuster(step: 1.0),
                CountryDisclosureBudgetAdjuster(factors: ["online": 1.04, "south": 1.12]),
                PercentDisclosureBudgetAdjuster(percent: -12.8),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 37515.0
        )
    }
}
