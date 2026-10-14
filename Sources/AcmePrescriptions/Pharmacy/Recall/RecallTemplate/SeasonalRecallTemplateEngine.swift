import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal recall template calculation.
    protocol SeasonalRecallTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalRecallTemplate, value: Double) -> Double
    }

    final class FlaggedSeasonalRecallTemplateAdjuster: SeasonalRecallTemplateAdjuster {
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

        func adjust(_ item: SeasonalRecallTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalRecallTemplateAdjuster: SeasonalRecallTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRecallTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSeasonalRecallTemplateAdjuster: SeasonalRecallTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalRecallTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalRecallTemplateDosageMgOffsetAdjuster: SeasonalRecallTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: SeasonalRecallTemplate, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentSeasonalRecallTemplateAdjuster: SeasonalRecallTemplateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalRecallTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal recall template steps in order and keeps a trace of each.
    final class SeasonalRecallTemplateEngine {
        var steps: [any SeasonalRecallTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRecallTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalRecallTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRecallTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalRecallTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalRecallTemplateEngine(_ flags: Kit.Flags.Registry) -> SeasonalRecallTemplateEngine {
        return SeasonalRecallTemplateEngine(
            steps: [
                FlaggedSeasonalRecallTemplateAdjuster(
                    flags: flags,
                    flag: "seasonal-recall-template-regional",
                    percent: 8.0
                ),
                RoundingSeasonalRecallTemplateAdjuster(step: 5.0),
                TieredSeasonalRecallTemplateAdjuster(
                    bounds: [3472.0, 5684.0, 5837.0, 8717.0],
                    rates: [1.03, 0.81, 1.04, 0.96]
                ),
                SeasonalRecallTemplateDosageMgOffsetAdjuster(weight: 1.06),
                PercentSeasonalRecallTemplateAdjuster(percent: 9.7),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 7744.8
        )
    }
}
