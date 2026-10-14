import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score baseline calculation.
    protocol RiskScoreBaselineModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreBaseline, value: Double) -> Double
    }

    final class NameRiskScoreBaselineAdjuster: RiskScoreBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RiskScoreBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRiskScoreBaselineAdjuster: RiskScoreBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRiskScoreBaselineAdjuster: RiskScoreBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRiskScoreBaselineAdjuster: RiskScoreBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRiskScoreBaselineAdjuster: RiskScoreBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the risk score baseline steps in order and keeps a trace of each.
    final class RiskScoreBaselineEngine {
        var steps: [any RiskScoreBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreBaseline) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreBaselineModifier = steps[index]
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

        func evaluateAll(_ items: [RiskScoreBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreBaselineEngine() -> RiskScoreBaselineEngine {
        return RiskScoreBaselineEngine(
            steps: [
                NameRiskScoreBaselineAdjuster(factors: ["west": 1.29, "retail": 1.06, "north": 1.1]),
                RoundingRiskScoreBaselineAdjuster(step: 1.0),
                CapRiskScoreBaselineAdjuster(cap: 6938.0),
                PercentRiskScoreBaselineAdjuster(percent: 20.3),
                MinimumRiskScoreBaselineAdjuster(minimum: 11.3),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 46537.4
        )
    }
}
