import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility window calculation.
    protocol EligibilityWindowStep {
        func describe() -> String
        func adjust(_ item: EligibilityWindow, value: Double) -> Double
    }

    final class PercentEligibilityWindowAdjuster: EligibilityWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class EligibilityWindowAmountOffsetAdjuster: EligibilityWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: EligibilityWindow, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredEligibilityWindowAdjuster: EligibilityWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumEligibilityWindowAdjuster: EligibilityWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the eligibility window steps in order and keeps a trace of each.
    final class EligibilityWindowEngine {
        var steps: [any EligibilityWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: EligibilityWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityWindowStep = steps[index]
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

        func evaluateAll(_ items: [EligibilityWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultEligibilityWindowEngine() -> EligibilityWindowEngine {
        return EligibilityWindowEngine(
            steps: [
                PercentEligibilityWindowAdjuster(percent: -21.6),
                EligibilityWindowAmountOffsetAdjuster(weight: 0.95),
                TieredEligibilityWindowAdjuster(bounds: [2608.0, 3945.0, 5701.0], rates: [1.08, 1.15, 1.01]),
                MinimumEligibilityWindowAdjuster(minimum: 12.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 60367.1
        )
    }
}
