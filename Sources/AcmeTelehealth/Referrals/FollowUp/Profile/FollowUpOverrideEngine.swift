import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up override calculation.
    protocol FollowUpOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpOverride, value: Double) -> Double
    }

    final class RoundingFollowUpOverrideAdjuster: FollowUpOverrideAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFollowUpOverrideAdjuster: FollowUpOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFollowUpOverrideAdjuster: FollowUpOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFollowUpOverrideAdjuster: FollowUpOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFollowUpOverrideAdjuster: FollowUpOverrideAdjuster {
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

        func adjust(_ item: FollowUpOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFollowUpOverrideAdjuster: FollowUpOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the follow up override steps in order and keeps a trace of each.
    final class FollowUpOverrideEngine {
        var steps: [any FollowUpOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpOverride) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [FollowUpOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpOverrideEngine(_ flags: Kit.Flags.Registry) -> FollowUpOverrideEngine {
        return FollowUpOverrideEngine(
            steps: [
                RoundingFollowUpOverrideAdjuster(step: 0.1),
                TieredFollowUpOverrideAdjuster(bounds: [6727.0, 9894.0], rates: [1.0, 0.85]),
                CapFollowUpOverrideAdjuster(cap: 11787.0),
                PercentFollowUpOverrideAdjuster(percent: 21.4),
                FlaggedFollowUpOverrideAdjuster(flags: flags, flag: "follow-up-override-fallback", percent: -7.9),
                MinimumFollowUpOverrideAdjuster(minimum: 4.8),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 40950.2
        )
    }
}
