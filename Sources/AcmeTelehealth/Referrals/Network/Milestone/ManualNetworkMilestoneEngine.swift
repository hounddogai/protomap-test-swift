import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network milestone calculation.
    protocol ManualNetworkMilestoneFactor {
        func describe() -> String
        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double
    }

    final class CapManualNetworkMilestoneAdjuster: ManualNetworkMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualNetworkMilestoneAdjuster: ManualNetworkMilestoneFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualNetworkMilestoneAdjuster: ManualNetworkMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualNetworkMilestoneAdjuster: ManualNetworkMilestoneFactor {
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

        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualNetworkMilestoneAdjuster: ManualNetworkMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualNetworkMilestoneAdjuster: ManualNetworkMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualNetworkMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual network milestone steps in order and keeps a trace of each.
    final class ManualNetworkMilestoneEngine {
        var steps: [any ManualNetworkMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualNetworkMilestone) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualNetworkMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [ManualNetworkMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualNetworkMilestoneEngine(_ flags: Kit.Flags.Registry) -> ManualNetworkMilestoneEngine {
        return ManualNetworkMilestoneEngine(
            steps: [
                CapManualNetworkMilestoneAdjuster(cap: 42680.0),
                RoundingManualNetworkMilestoneAdjuster(step: 0.05),
                TieredManualNetworkMilestoneAdjuster(bounds: [3608.0, 9112.0], rates: [0.99, 1.13]),
                FlaggedManualNetworkMilestoneAdjuster(
                    flags: flags,
                    flag: "manual-network-milestone-seasonal",
                    percent: -4.4
                ),
                MinimumManualNetworkMilestoneAdjuster(minimum: 49.7),
                PercentManualNetworkMilestoneAdjuster(percent: -1.3),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 76063.1
        )
    }
}
