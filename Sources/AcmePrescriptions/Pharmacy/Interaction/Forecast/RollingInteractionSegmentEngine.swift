import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling interaction segment calculation.
    protocol RollingInteractionSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: RollingInteractionSegment, value: Double) -> Double
    }

    final class MinimumRollingInteractionSegmentAdjuster: RollingInteractionSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingInteractionSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingInteractionSegmentAdjuster: RollingInteractionSegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingInteractionSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingInteractionSegmentEndsAtOffsetAdjuster: RollingInteractionSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: RollingInteractionSegment, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class RoundingRollingInteractionSegmentAdjuster: RollingInteractionSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingInteractionSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingInteractionSegmentAdjuster: RollingInteractionSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingInteractionSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling interaction segment steps in order and keeps a trace of each.
    final class RollingInteractionSegmentEngine {
        var steps: [any RollingInteractionSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingInteractionSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingInteractionSegment) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingInteractionSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingInteractionSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingInteractionSegmentEngine() -> RollingInteractionSegmentEngine {
        return RollingInteractionSegmentEngine(
            steps: [
                MinimumRollingInteractionSegmentAdjuster(minimum: 47.3),
                PercentRollingInteractionSegmentAdjuster(percent: -14.0),
                RollingInteractionSegmentEndsAtOffsetAdjuster(weight: 1.86),
                RoundingRollingInteractionSegmentAdjuster(step: 0.05),
                CapRollingInteractionSegmentAdjuster(cap: 27301.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 75548.7
        )
    }
}
