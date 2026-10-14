import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal worklist template calculation.
    protocol SeasonalWorklistTemplateModifier {
        func describe() -> String
        func adjust(_ item: SeasonalWorklistTemplate, value: Double) -> Double
    }

    final class MinimumSeasonalWorklistTemplateAdjuster: SeasonalWorklistTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalWorklistTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalWorklistTemplateAdjuster: SeasonalWorklistTemplateModifier {
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

        func adjust(_ item: SeasonalWorklistTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSeasonalWorklistTemplateAdjuster: SeasonalWorklistTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalWorklistTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalWorklistTemplateAdjuster: SeasonalWorklistTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalWorklistTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal worklist template steps in order and keeps a trace of each.
    final class SeasonalWorklistTemplateEngine {
        var steps: [any SeasonalWorklistTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalWorklistTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalWorklistTemplate) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [SeasonalWorklistTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalWorklistTemplateEngine(_ flags: Kit.Flags.Registry) -> SeasonalWorklistTemplateEngine {
        return SeasonalWorklistTemplateEngine(
            steps: [
                MinimumSeasonalWorklistTemplateAdjuster(minimum: 36.1),
                FlaggedSeasonalWorklistTemplateAdjuster(
                    flags: flags,
                    flag: "seasonal-worklist-template-capped",
                    percent: -7.1
                ),
                TitleSeasonalWorklistTemplateAdjuster(factors: ["north": 1.37, "west": 1.29, "central": 1.13]),
                TieredSeasonalWorklistTemplateAdjuster(
                    bounds: [215.0, 2277.0, 2872.0, 5171.0],
                    rates: [0.83, 1.19, 1.14, 1.19]
                ),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 87059.0
        )
    }
}
