import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal float pool template calculation.
    protocol SeasonalFloatPoolTemplateFactor {
        func describe() -> String
        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double
    }

    final class PercentSeasonalFloatPoolTemplateAdjuster: SeasonalFloatPoolTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalFloatPoolTemplateAdjuster: SeasonalFloatPoolTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalFloatPoolTemplateAdjuster: SeasonalFloatPoolTemplateFactor {
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

        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalFloatPoolTemplateAdjuster: SeasonalFloatPoolTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalFloatPoolTemplateAdjuster: SeasonalFloatPoolTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelSeasonalFloatPoolTemplateAdjuster: SeasonalFloatPoolTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalFloatPoolTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal float pool template steps in order and keeps a trace of each.
    final class SeasonalFloatPoolTemplateEngine {
        var steps: [any SeasonalFloatPoolTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalFloatPoolTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalFloatPoolTemplate) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [SeasonalFloatPoolTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalFloatPoolTemplateEngine(_ flags: Kit.Flags.Registry) -> SeasonalFloatPoolTemplateEngine {
        return SeasonalFloatPoolTemplateEngine(
            steps: [
                PercentSeasonalFloatPoolTemplateAdjuster(percent: 21.8),
                MinimumSeasonalFloatPoolTemplateAdjuster(minimum: 20.2),
                FlaggedSeasonalFloatPoolTemplateAdjuster(
                    flags: flags,
                    flag: "seasonal-float-pool-template-weighted",
                    percent: 9.8
                ),
                CapSeasonalFloatPoolTemplateAdjuster(cap: 11289.0),
                RoundingSeasonalFloatPoolTemplateAdjuster(step: 5.0),
                LabelSeasonalFloatPoolTemplateAdjuster(factors: ["retail": 1.37]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 90423.2
        )
    }
}
