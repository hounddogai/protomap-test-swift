import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure rollup calculation.
    protocol ClosureRollupModifier {
        func describe() -> String
        func adjust(_ item: ClosureRollup, value: Double) -> Double
    }

    final class NameClosureRollupAdjuster: ClosureRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClosureRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClosureRollupAdjuster: ClosureRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClosureRollupAdjuster: ClosureRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ClosureRollupAttemptsOffsetAdjuster: ClosureRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ClosureRollup, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapClosureRollupAdjuster: ClosureRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumClosureRollupAdjuster: ClosureRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the closure rollup steps in order and keeps a trace of each.
    final class ClosureRollupEngine {
        var steps: [any ClosureRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosureRollup) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureRollupModifier = steps[index]
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

        func evaluateAll(_ items: [ClosureRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosureRollupEngine() -> ClosureRollupEngine {
        return ClosureRollupEngine(
            steps: [
                NameClosureRollupAdjuster(factors: ["central": 0.89, "east": 1.37]),
                PercentClosureRollupAdjuster(percent: 17.1),
                RoundingClosureRollupAdjuster(step: 1.0),
                ClosureRollupAttemptsOffsetAdjuster(weight: 1.24),
                CapClosureRollupAdjuster(cap: 23861.0),
                MinimumClosureRollupAdjuster(minimum: 31.3),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 58244.8
        )
    }
}
