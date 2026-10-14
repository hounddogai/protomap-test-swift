import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling float pool score calculation.
    protocol RollingFloatPoolScoreAdjuster {
        func describe() -> String
        func adjust(_ item: RollingFloatPoolScore, value: Double) -> Double
    }

    final class CapRollingFloatPoolScoreAdjuster: RollingFloatPoolScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingFloatPoolScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRollingFloatPoolScoreAdjuster: RollingFloatPoolScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingFloatPoolScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingFloatPoolScoreBudgetOffsetAdjuster: RollingFloatPoolScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: RollingFloatPoolScore, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class MinimumRollingFloatPoolScoreAdjuster: RollingFloatPoolScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingFloatPoolScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleRollingFloatPoolScoreAdjuster: RollingFloatPoolScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RollingFloatPoolScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling float pool score steps in order and keeps a trace of each.
    final class RollingFloatPoolScoreEngine {
        var steps: [any RollingFloatPoolScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFloatPoolScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingFloatPoolScore) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingFloatPoolScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingFloatPoolScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingFloatPoolScoreEngine() -> RollingFloatPoolScoreEngine {
        return RollingFloatPoolScoreEngine(
            steps: [
                CapRollingFloatPoolScoreAdjuster(cap: 32848.0),
                PercentRollingFloatPoolScoreAdjuster(percent: 14.1),
                RollingFloatPoolScoreBudgetOffsetAdjuster(weight: 0.24),
                MinimumRollingFloatPoolScoreAdjuster(minimum: 49.2),
                LocaleRollingFloatPoolScoreAdjuster(factors: ["east": 1.06, "retail": 0.85, "west": 1.36]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 9479.5
        )
    }
}
