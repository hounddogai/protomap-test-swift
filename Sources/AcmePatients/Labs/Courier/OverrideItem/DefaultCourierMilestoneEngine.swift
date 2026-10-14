import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default courier milestone calculation.
    protocol DefaultCourierMilestoneFactor {
        func describe() -> String
        func adjust(_ item: DefaultCourierMilestone, value: Double) -> Double
    }

    final class TieredDefaultCourierMilestoneAdjuster: DefaultCourierMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCourierMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultCourierMilestoneAdjuster: DefaultCourierMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCourierMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDefaultCourierMilestoneAdjuster: DefaultCourierMilestoneFactor {
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

        func adjust(_ item: DefaultCourierMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default courier milestone steps in order and keeps a trace of each.
    final class DefaultCourierMilestoneEngine {
        var steps: [any DefaultCourierMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCourierMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCourierMilestone) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCourierMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultCourierMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCourierMilestoneEngine(_ flags: Kit.Flags.Registry) -> DefaultCourierMilestoneEngine {
        return DefaultCourierMilestoneEngine(
            steps: [
                TieredDefaultCourierMilestoneAdjuster(
                    bounds: [548.0, 5998.0, 7332.0, 8723.0],
                    rates: [0.99, 0.99, 1.07, 0.93]
                ),
                PercentDefaultCourierMilestoneAdjuster(percent: -8.7),
                FlaggedDefaultCourierMilestoneAdjuster(
                    flags: flags,
                    flag: "default-courier-milestone-global",
                    percent: 8.1
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 23925.3
        )
    }
}
