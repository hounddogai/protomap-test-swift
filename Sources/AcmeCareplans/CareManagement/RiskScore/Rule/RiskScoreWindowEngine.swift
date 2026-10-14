import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score window calculation.
    protocol RiskScoreWindowFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreWindow, value: Double) -> Double
    }

    final class TitleRiskScoreWindowAdjuster: RiskScoreWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RiskScoreWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRiskScoreWindowAdjuster: RiskScoreWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRiskScoreWindowAdjuster: RiskScoreWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRiskScoreWindowAdjuster: RiskScoreWindowFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RiskScoreWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRiskScoreWindowAdjuster: RiskScoreWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the risk score window steps in order and keeps a trace of each.
    final class RiskScoreWindowEngine {
        var steps: [any RiskScoreWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreWindow) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreWindowFactor = steps[index]
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

        func evaluateAll(_ items: [RiskScoreWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreWindowEngine(_ flags: Kit.Flags.Registry) -> RiskScoreWindowEngine {
        return RiskScoreWindowEngine(
            steps: [
                TitleRiskScoreWindowAdjuster(factors: ["north": 0.85]),
                MinimumRiskScoreWindowAdjuster(minimum: 18.1),
                CapRiskScoreWindowAdjuster(cap: 14128.0),
                FlaggedRiskScoreWindowAdjuster(flags: flags, flag: "risk-score-window-capped", percent: 8.8),
                RoundingRiskScoreWindowAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 64019.8
        )
    }
}
