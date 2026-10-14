import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert segment calculation.
    protocol AlertSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: AlertSegment, value: Double) -> Double
    }

    final class RoundingAlertSegmentAdjuster: AlertSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAlertSegmentAdjuster: AlertSegmentAdjuster {
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

        func adjust(_ item: AlertSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AlertSegmentAttemptsOffsetAdjuster: AlertSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: AlertSegment, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapAlertSegmentAdjuster: AlertSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAlertSegmentAdjuster: AlertSegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the alert segment steps in order and keeps a trace of each.
    final class AlertSegmentEngine {
        var steps: [any AlertSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AlertSegment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [AlertSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAlertSegmentEngine(_ flags: Kit.Flags.Registry) -> AlertSegmentEngine {
        return AlertSegmentEngine(
            steps: [
                RoundingAlertSegmentAdjuster(step: 5.0),
                FlaggedAlertSegmentAdjuster(flags: flags, flag: "alert-segment-strict", percent: -5.2),
                AlertSegmentAttemptsOffsetAdjuster(weight: 0.18),
                CapAlertSegmentAdjuster(cap: 11270.0),
                PercentAlertSegmentAdjuster(percent: 9.6),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 59673.6
        )
    }
}
