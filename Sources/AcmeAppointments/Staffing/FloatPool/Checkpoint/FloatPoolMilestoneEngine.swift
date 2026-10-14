import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool milestone calculation.
    protocol FloatPoolMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolMilestone, value: Double) -> Double
    }

    final class PercentFloatPoolMilestoneAdjuster: FloatPoolMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FloatPoolMilestoneCapacityOffsetAdjuster: FloatPoolMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: FloatPoolMilestone, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredFloatPoolMilestoneAdjuster: FloatPoolMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFloatPoolMilestoneAdjuster: FloatPoolMilestoneAdjuster {
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

        func adjust(_ item: FloatPoolMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool milestone steps in order and keeps a trace of each.
    final class FloatPoolMilestoneEngine {
        var steps: [any FloatPoolMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolMilestone) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolMilestoneEngine(_ flags: Kit.Flags.Registry) -> FloatPoolMilestoneEngine {
        return FloatPoolMilestoneEngine(
            steps: [
                PercentFloatPoolMilestoneAdjuster(percent: 11.2),
                FloatPoolMilestoneCapacityOffsetAdjuster(weight: 1.47),
                TieredFloatPoolMilestoneAdjuster(bounds: [1501.0, 6874.0], rates: [0.86, 0.94]),
                FlaggedFloatPoolMilestoneAdjuster(flags: flags, flag: "float-pool-milestone-pending", percent: -3.9),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 27905.1
        )
    }
}
