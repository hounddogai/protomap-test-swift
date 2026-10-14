import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback float pool milestone calculation.
    protocol FallbackFloatPoolMilestoneFactor {
        func describe() -> String
        func adjust(_ item: FallbackFloatPoolMilestone, value: Double) -> Double
    }

    final class RoundingFallbackFloatPoolMilestoneAdjuster: FallbackFloatPoolMilestoneFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackFloatPoolMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackFloatPoolMilestoneAdjuster: FallbackFloatPoolMilestoneFactor {
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

        func adjust(_ item: FallbackFloatPoolMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackFloatPoolMilestoneAdjuster: FallbackFloatPoolMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackFloatPoolMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackFloatPoolMilestoneAdjuster: FallbackFloatPoolMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackFloatPoolMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback float pool milestone steps in order and keeps a trace of each.
    final class FallbackFloatPoolMilestoneEngine {
        var steps: [any FallbackFloatPoolMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFloatPoolMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackFloatPoolMilestone) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackFloatPoolMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackFloatPoolMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackFloatPoolMilestoneEngine(_ flags: Kit.Flags.Registry) -> FallbackFloatPoolMilestoneEngine {
        return FallbackFloatPoolMilestoneEngine(
            steps: [
                RoundingFallbackFloatPoolMilestoneAdjuster(step: 0.05),
                FlaggedFallbackFloatPoolMilestoneAdjuster(
                    flags: flags,
                    flag: "fallback-float-pool-milestone-scheduled",
                    percent: -5.9
                ),
                PercentFallbackFloatPoolMilestoneAdjuster(percent: -24.4),
                MinimumFallbackFloatPoolMilestoneAdjuster(minimum: 11.1),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 34333.8
        )
    }
}
