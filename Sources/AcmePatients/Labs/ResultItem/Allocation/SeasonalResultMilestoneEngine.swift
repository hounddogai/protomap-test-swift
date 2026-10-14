import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal result milestone calculation.
    protocol SeasonalResultMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double
    }

    final class PercentSeasonalResultMilestoneAdjuster: SeasonalResultMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilitySeasonalResultMilestoneAdjuster: SeasonalResultMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalResultMilestoneAdjuster: SeasonalResultMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalResultMilestoneAdjuster: SeasonalResultMilestoneAdjuster {
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

        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalResultMilestoneSequenceOffsetAdjuster: SeasonalResultMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapSeasonalResultMilestoneAdjuster: SeasonalResultMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalResultMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal result milestone steps in order and keeps a trace of each.
    final class SeasonalResultMilestoneEngine {
        var steps: [any SeasonalResultMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalResultMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalResultMilestone) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalResultMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalResultMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalResultMilestoneEngine(_ flags: Kit.Flags.Registry) -> SeasonalResultMilestoneEngine {
        return SeasonalResultMilestoneEngine(
            steps: [
                PercentSeasonalResultMilestoneAdjuster(percent: 9.4),
                FacilitySeasonalResultMilestoneAdjuster(factors: ["retail": 0.88, "south": 1.09, "central": 1.38]),
                TieredSeasonalResultMilestoneAdjuster(bounds: [6145.0, 7913.0, 9171.0], rates: [1.17, 0.82, 0.97]),
                FlaggedSeasonalResultMilestoneAdjuster(
                    flags: flags,
                    flag: "seasonal-result-milestone-manual",
                    percent: 9.8
                ),
                SeasonalResultMilestoneSequenceOffsetAdjuster(weight: 0.33),
                CapSeasonalResultMilestoneAdjuster(cap: 12277.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 16271.8
        )
    }
}
