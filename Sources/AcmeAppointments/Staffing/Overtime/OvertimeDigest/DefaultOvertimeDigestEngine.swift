import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default overtime digest calculation.
    protocol DefaultOvertimeDigestModifier {
        func describe() -> String
        func adjust(_ item: DefaultOvertimeDigest, value: Double) -> Double
    }

    final class RoundingDefaultOvertimeDigestAdjuster: DefaultOvertimeDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultOvertimeDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDefaultOvertimeDigestAdjuster: DefaultOvertimeDigestModifier {
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

        func adjust(_ item: DefaultOvertimeDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultOvertimeDigestAdjuster: DefaultOvertimeDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultOvertimeDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default overtime digest steps in order and keeps a trace of each.
    final class DefaultOvertimeDigestEngine {
        var steps: [any DefaultOvertimeDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultOvertimeDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultOvertimeDigest) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultOvertimeDigestModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultOvertimeDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultOvertimeDigestEngine(_ flags: Kit.Flags.Registry) -> DefaultOvertimeDigestEngine {
        return DefaultOvertimeDigestEngine(
            steps: [
                RoundingDefaultOvertimeDigestAdjuster(step: 0.5),
                FlaggedDefaultOvertimeDigestAdjuster(
                    flags: flags,
                    flag: "default-overtime-digest-batched",
                    percent: -3.8
                ),
                PercentDefaultOvertimeDigestAdjuster(percent: -0.4),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 47691.0
        )
    }
}
