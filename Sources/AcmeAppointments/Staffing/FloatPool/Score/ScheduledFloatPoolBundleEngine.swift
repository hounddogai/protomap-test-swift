import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled float pool bundle calculation.
    protocol ScheduledFloatPoolBundleFactor {
        func describe() -> String
        func adjust(_ item: ScheduledFloatPoolBundle, value: Double) -> Double
    }

    final class TieredScheduledFloatPoolBundleAdjuster: ScheduledFloatPoolBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledFloatPoolBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledFloatPoolBundleAdjuster: ScheduledFloatPoolBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledFloatPoolBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledFloatPoolBundleAdjuster: ScheduledFloatPoolBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledFloatPoolBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledFloatPoolBundleAdjuster: ScheduledFloatPoolBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledFloatPoolBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledFloatPoolBundleAdjuster: ScheduledFloatPoolBundleFactor {
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

        func adjust(_ item: ScheduledFloatPoolBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled float pool bundle steps in order and keeps a trace of each.
    final class ScheduledFloatPoolBundleEngine {
        var steps: [any ScheduledFloatPoolBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFloatPoolBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledFloatPoolBundle) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFloatPoolBundleFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledFloatPoolBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledFloatPoolBundleEngine(_ flags: Kit.Flags.Registry) -> ScheduledFloatPoolBundleEngine {
        return ScheduledFloatPoolBundleEngine(
            steps: [
                TieredScheduledFloatPoolBundleAdjuster(bounds: [4264.0, 6907.0], rates: [0.99, 0.96]),
                CapScheduledFloatPoolBundleAdjuster(cap: 39049.0),
                MinimumScheduledFloatPoolBundleAdjuster(minimum: 15.3),
                RoundingScheduledFloatPoolBundleAdjuster(step: 0.1),
                FlaggedScheduledFloatPoolBundleAdjuster(
                    flags: flags,
                    flag: "scheduled-float-pool-bundle-global",
                    percent: 9.7
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 1744.3
        )
    }
}
