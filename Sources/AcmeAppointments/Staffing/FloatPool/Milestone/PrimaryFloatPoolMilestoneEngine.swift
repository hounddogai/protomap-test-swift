import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary float pool milestone calculation.
    protocol PrimaryFloatPoolMilestoneFactor {
        func describe() -> String
        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double
    }

    final class FlaggedPrimaryFloatPoolMilestoneAdjuster: PrimaryFloatPoolMilestoneFactor {
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

        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryFloatPoolMilestoneAdjuster: PrimaryFloatPoolMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryPrimaryFloatPoolMilestoneAdjuster: PrimaryFloatPoolMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryFloatPoolMilestoneAdjuster: PrimaryFloatPoolMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryFloatPoolMilestoneAdjuster: PrimaryFloatPoolMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryFloatPoolMilestoneAdjuster: PrimaryFloatPoolMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryFloatPoolMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary float pool milestone steps in order and keeps a trace of each.
    final class PrimaryFloatPoolMilestoneEngine {
        var steps: [any PrimaryFloatPoolMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryFloatPoolMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryFloatPoolMilestone) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryFloatPoolMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryFloatPoolMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryFloatPoolMilestoneEngine(_ flags: Kit.Flags.Registry) -> PrimaryFloatPoolMilestoneEngine {
        return PrimaryFloatPoolMilestoneEngine(
            steps: [
                FlaggedPrimaryFloatPoolMilestoneAdjuster(
                    flags: flags,
                    flag: "primary-float-pool-milestone-capped",
                    percent: 6.6
                ),
                PercentPrimaryFloatPoolMilestoneAdjuster(percent: -3.0),
                CategoryPrimaryFloatPoolMilestoneAdjuster(factors: ["west": 0.75, "east": 1.07, "retail": 0.75]),
                TieredPrimaryFloatPoolMilestoneAdjuster(bounds: [2781.0, 7944.0], rates: [0.98, 1.12]),
                CapPrimaryFloatPoolMilestoneAdjuster(cap: 47593.0),
                MinimumPrimaryFloatPoolMilestoneAdjuster(minimum: 23.2),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 98181.0
        )
    }
}
