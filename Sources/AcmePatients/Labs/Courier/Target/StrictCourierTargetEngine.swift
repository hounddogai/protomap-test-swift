import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict courier target calculation.
    protocol StrictCourierTargetModifier {
        func describe() -> String
        func adjust(_ item: StrictCourierTarget, value: Double) -> Double
    }

    final class RoundingStrictCourierTargetAdjuster: StrictCourierTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCourierTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStrictCourierTargetAdjuster: StrictCourierTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCourierTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameStrictCourierTargetAdjuster: StrictCourierTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictCourierTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictCourierTargetAdjuster: StrictCourierTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCourierTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict courier target steps in order and keeps a trace of each.
    final class StrictCourierTargetEngine {
        var steps: [any StrictCourierTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCourierTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictCourierTarget) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictCourierTargetModifier = steps[index]
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

        func evaluateAll(_ items: [StrictCourierTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictCourierTargetEngine() -> StrictCourierTargetEngine {
        return StrictCourierTargetEngine(
            steps: [
                RoundingStrictCourierTargetAdjuster(step: 1.0),
                PercentStrictCourierTargetAdjuster(percent: 19.0),
                NameStrictCourierTargetAdjuster(factors: ["east": 1.18, "south": 1.02, "west": 0.9]),
                MinimumStrictCourierTargetAdjuster(minimum: 2.4),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 73260.5
        )
    }
}
