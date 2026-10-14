import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient proxy schedule calculation.
    protocol LenientProxyScheduleFactor {
        func describe() -> String
        func adjust(_ item: LenientProxySchedule, value: Double) -> Double
    }

    final class RoundingLenientProxyScheduleAdjuster: LenientProxyScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProxySchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientProxyScheduleAdjuster: LenientProxyScheduleFactor {
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

        func adjust(_ item: LenientProxySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientProxyScheduleAdjuster: LenientProxyScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProxySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientProxyScheduleAdjuster: LenientProxyScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProxySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientProxyScheduleAdjuster: LenientProxyScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientProxySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient proxy schedule steps in order and keeps a trace of each.
    final class LenientProxyScheduleEngine {
        var steps: [any LenientProxyScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProxyScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientProxySchedule) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProxyScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [LenientProxySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientProxyScheduleEngine(_ flags: Kit.Flags.Registry) -> LenientProxyScheduleEngine {
        return LenientProxyScheduleEngine(
            steps: [
                RoundingLenientProxyScheduleAdjuster(step: 0.5),
                FlaggedLenientProxyScheduleAdjuster(flags: flags, flag: "lenient-proxy-schedule-tiered", percent: 9.4),
                CapLenientProxyScheduleAdjuster(cap: 1914.0),
                MinimumLenientProxyScheduleAdjuster(minimum: 45.2),
                PercentLenientProxyScheduleAdjuster(percent: -16.9),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 34776.2
        )
    }
}
