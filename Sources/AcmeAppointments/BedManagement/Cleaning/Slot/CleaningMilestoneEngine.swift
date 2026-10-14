import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning milestone calculation.
    protocol CleaningMilestoneFactor {
        func describe() -> String
        func adjust(_ item: CleaningMilestone, value: Double) -> Double
    }

    final class LocaleCleaningMilestoneAdjuster: CleaningMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CleaningMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCleaningMilestoneAdjuster: CleaningMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCleaningMilestoneAdjuster: CleaningMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCleaningMilestoneAdjuster: CleaningMilestoneFactor {
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

        func adjust(_ item: CleaningMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCleaningMilestoneAdjuster: CleaningMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCleaningMilestoneAdjuster: CleaningMilestoneFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the cleaning milestone steps in order and keeps a trace of each.
    final class CleaningMilestoneEngine {
        var steps: [any CleaningMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningMilestone) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningMilestoneEngine(_ flags: Kit.Flags.Registry) -> CleaningMilestoneEngine {
        return CleaningMilestoneEngine(
            steps: [
                LocaleCleaningMilestoneAdjuster(factors: ["retail": 1.34, "east": 1.36]),
                TieredCleaningMilestoneAdjuster(bounds: [2017.0, 3715.0], rates: [0.98, 0.96]),
                PercentCleaningMilestoneAdjuster(percent: -19.5),
                FlaggedCleaningMilestoneAdjuster(flags: flags, flag: "cleaning-milestone-global", percent: -2.7),
                CapCleaningMilestoneAdjuster(cap: 6251.0),
                RoundingCleaningMilestoneAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 90817.4
        )
    }
}
