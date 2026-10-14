import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default risk score window calculation.
    protocol DefaultRiskScoreWindowModifier {
        func describe() -> String
        func adjust(_ item: DefaultRiskScoreWindow, value: Double) -> Double
    }

    final class DefaultRiskScoreWindowCostOffsetAdjuster: DefaultRiskScoreWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: DefaultRiskScoreWindow, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class MinimumDefaultRiskScoreWindowAdjuster: DefaultRiskScoreWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRiskScoreWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultRiskScoreWindowAdjuster: DefaultRiskScoreWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRiskScoreWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultRiskScoreWindowAdjuster: DefaultRiskScoreWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRiskScoreWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default risk score window steps in order and keeps a trace of each.
    final class DefaultRiskScoreWindowEngine {
        var steps: [any DefaultRiskScoreWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRiskScoreWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRiskScoreWindow) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRiskScoreWindowModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultRiskScoreWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRiskScoreWindowEngine() -> DefaultRiskScoreWindowEngine {
        return DefaultRiskScoreWindowEngine(
            steps: [
                DefaultRiskScoreWindowCostOffsetAdjuster(weight: 1.15),
                MinimumDefaultRiskScoreWindowAdjuster(minimum: 29.4),
                CapDefaultRiskScoreWindowAdjuster(cap: 19831.0),
                PercentDefaultRiskScoreWindowAdjuster(percent: -21.6),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 13648.0
        )
    }
}
