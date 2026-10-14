import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier segment calculation.
    protocol CourierSegmentModifier {
        func describe() -> String
        func adjust(_ item: CourierSegment, value: Double) -> Double
    }

    final class CourierSegmentMinimumOffsetAdjuster: CourierSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: CourierSegment, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class PercentCourierSegmentAdjuster: CourierSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCourierSegmentAdjuster: CourierSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCourierSegmentAdjuster: CourierSegmentModifier {
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

        func adjust(_ item: CourierSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCourierSegmentAdjuster: CourierSegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the courier segment steps in order and keeps a trace of each.
    final class CourierSegmentEngine {
        var steps: [any CourierSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierSegment) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [CourierSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierSegmentEngine(_ flags: Kit.Flags.Registry) -> CourierSegmentEngine {
        return CourierSegmentEngine(
            steps: [
                CourierSegmentMinimumOffsetAdjuster(weight: 0.28),
                PercentCourierSegmentAdjuster(percent: 20.4),
                RoundingCourierSegmentAdjuster(step: 1.0),
                FlaggedCourierSegmentAdjuster(flags: flags, flag: "courier-segment-legacy", percent: -9.4),
                CapCourierSegmentAdjuster(cap: 5960.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 2829.6
        )
    }
}
