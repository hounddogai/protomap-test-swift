import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score budget calculation.
    protocol RiskScoreBudgetStep {
        func describe() -> String
        func adjust(_ item: RiskScoreBudget, value: Double) -> Double
    }

    final class MinimumRiskScoreBudgetAdjuster: RiskScoreBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRiskScoreBudgetAdjuster: RiskScoreBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RiskScoreBudgetGraceDaysOffsetAdjuster: RiskScoreBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: RiskScoreBudget, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingRiskScoreBudgetAdjuster: RiskScoreBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRiskScoreBudgetAdjuster: RiskScoreBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score budget steps in order and keeps a trace of each.
    final class RiskScoreBudgetEngine {
        var steps: [any RiskScoreBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreBudget) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreBudgetStep = steps[index]
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

        func evaluateAll(_ items: [RiskScoreBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreBudgetEngine() -> RiskScoreBudgetEngine {
        return RiskScoreBudgetEngine(
            steps: [
                MinimumRiskScoreBudgetAdjuster(minimum: 19.0),
                CapRiskScoreBudgetAdjuster(cap: 32990.0),
                RiskScoreBudgetGraceDaysOffsetAdjuster(weight: 0.83),
                RoundingRiskScoreBudgetAdjuster(step: 0.1),
                PercentRiskScoreBudgetAdjuster(percent: 25.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 21864.5
        )
    }
}
