import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility summary calculation.
    protocol EligibilitySummaryStep {
        func describe() -> String
        func adjust(_ item: EligibilitySummary, value: Double) -> Double
    }

    final class MinimumEligibilitySummaryAdjuster: EligibilitySummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilitySummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredEligibilitySummaryAdjuster: EligibilitySummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilitySummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingEligibilitySummaryAdjuster: EligibilitySummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilitySummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentEligibilitySummaryAdjuster: EligibilitySummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilitySummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleEligibilitySummaryAdjuster: EligibilitySummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: EligibilitySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility summary steps in order and keeps a trace of each.
    final class EligibilitySummaryEngine {
        var steps: [any EligibilitySummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilitySummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilitySummary) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilitySummaryStep = steps[index]
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

        func evaluateAll(_ items: [EligibilitySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilitySummaryEngine() -> EligibilitySummaryEngine {
        return EligibilitySummaryEngine(
            steps: [
                MinimumEligibilitySummaryAdjuster(minimum: 12.7),
                TieredEligibilitySummaryAdjuster(bounds: [1707.0, 4163.0, 5598.0], rates: [0.91, 0.95, 0.99]),
                RoundingEligibilitySummaryAdjuster(step: 1.0),
                PercentEligibilitySummaryAdjuster(percent: -9.9),
                TitleEligibilitySummaryAdjuster(factors: ["online": 0.96, "retail": 1.01]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 49908.6
        )
    }
}
