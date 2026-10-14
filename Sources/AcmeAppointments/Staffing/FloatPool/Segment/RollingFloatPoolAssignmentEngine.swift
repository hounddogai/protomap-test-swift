import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling float pool assignment calculation.
    protocol RollingFloatPoolAssignmentStep {
        func describe() -> String
        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double
    }

    final class RoundingRollingFloatPoolAssignmentAdjuster: RollingFloatPoolAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingFloatPoolAssignmentAttemptsOffsetAdjuster: RollingFloatPoolAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class ChannelRollingFloatPoolAssignmentAdjuster: RollingFloatPoolAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingFloatPoolAssignmentAdjuster: RollingFloatPoolAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingFloatPoolAssignmentAdjuster: RollingFloatPoolAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingFloatPoolAssignmentAdjuster: RollingFloatPoolAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingFloatPoolAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling float pool assignment steps in order and keeps a trace of each.
    final class RollingFloatPoolAssignmentEngine {
        var steps: [any RollingFloatPoolAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFloatPoolAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingFloatPoolAssignment) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RollingFloatPoolAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingFloatPoolAssignmentEngine() -> RollingFloatPoolAssignmentEngine {
        return RollingFloatPoolAssignmentEngine(
            steps: [
                RoundingRollingFloatPoolAssignmentAdjuster(step: 5.0),
                RollingFloatPoolAssignmentAttemptsOffsetAdjuster(weight: 0.04),
                ChannelRollingFloatPoolAssignmentAdjuster(factors: ["east": 1.07, "south": 1.22]),
                MinimumRollingFloatPoolAssignmentAdjuster(minimum: 27.4),
                PercentRollingFloatPoolAssignmentAdjuster(percent: 11.3),
                CapRollingFloatPoolAssignmentAdjuster(cap: 29633.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 18218.2
        )
    }
}
