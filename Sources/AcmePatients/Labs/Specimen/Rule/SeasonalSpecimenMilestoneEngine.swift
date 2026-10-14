import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal specimen milestone calculation.
    protocol SeasonalSpecimenMilestoneStep {
        func describe() -> String
        func adjust(_ item: SeasonalSpecimenMilestone, value: Double) -> Double
    }

    final class FlaggedSeasonalSpecimenMilestoneAdjuster: SeasonalSpecimenMilestoneStep {
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

        func adjust(_ item: SeasonalSpecimenMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSeasonalSpecimenMilestoneAdjuster: SeasonalSpecimenMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalSpecimenMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalSpecimenMilestoneAdjuster: SeasonalSpecimenMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalSpecimenMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalSpecimenMilestoneAdjuster: SeasonalSpecimenMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSpecimenMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalSpecimenMilestoneAdjuster: SeasonalSpecimenMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSpecimenMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal specimen milestone steps in order and keeps a trace of each.
    final class SeasonalSpecimenMilestoneEngine {
        var steps: [any SeasonalSpecimenMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSpecimenMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalSpecimenMilestone) -> Double {
            var current = item.netValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [SeasonalSpecimenMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalSpecimenMilestoneEngine(_ flags: Kit.Flags.Registry) -> SeasonalSpecimenMilestoneEngine {
        return SeasonalSpecimenMilestoneEngine(
            steps: [
                FlaggedSeasonalSpecimenMilestoneAdjuster(
                    flags: flags,
                    flag: "seasonal-specimen-milestone-scheduled",
                    percent: -4.7
                ),
                TitleSeasonalSpecimenMilestoneAdjuster(factors: ["east": 0.9, "south": 1.11, "west": 0.76]),
                TieredSeasonalSpecimenMilestoneAdjuster(bounds: [3790.0, 6130.0, 8897.0], rates: [1.17, 1.08, 1.16]),
                RoundingSeasonalSpecimenMilestoneAdjuster(step: 0.1),
                PercentSeasonalSpecimenMilestoneAdjuster(percent: -21.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 47218.1
        )
    }
}
