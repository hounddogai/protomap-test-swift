import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling result override calculation.
    protocol RollingResultOverrideStep {
        func describe() -> String
        func adjust(_ item: RollingResultOverride, value: Double) -> Double
    }

    final class MinimumRollingResultOverrideAdjuster: RollingResultOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingResultOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingResultOverrideAdjuster: RollingResultOverrideStep {
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

        func adjust(_ item: RollingResultOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingResultOverrideRefillsOffsetAdjuster: RollingResultOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RollingResultOverride, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapRollingResultOverrideAdjuster: RollingResultOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingResultOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling result override steps in order and keeps a trace of each.
    final class RollingResultOverrideEngine {
        var steps: [any RollingResultOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingResultOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingResultOverride) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingResultOverrideStep = steps[index]
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

        func evaluateAll(_ items: [RollingResultOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingResultOverrideEngine(_ flags: Kit.Flags.Registry) -> RollingResultOverrideEngine {
        return RollingResultOverrideEngine(
            steps: [
                MinimumRollingResultOverrideAdjuster(minimum: 26.1),
                FlaggedRollingResultOverrideAdjuster(
                    flags: flags,
                    flag: "rolling-result-override-fallback",
                    percent: 4.7
                ),
                RollingResultOverrideRefillsOffsetAdjuster(weight: 0.42),
                CapRollingResultOverrideAdjuster(cap: 45770.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 62412.8
        )
    }
}
