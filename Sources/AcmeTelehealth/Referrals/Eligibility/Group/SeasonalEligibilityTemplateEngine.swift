import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal eligibility template calculation.
    protocol SeasonalEligibilityTemplateFactor {
        func describe() -> String
        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double
    }

    final class SeasonalEligibilityTemplateAmountOffsetAdjuster: SeasonalEligibilityTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentSeasonalEligibilityTemplateAdjuster: SeasonalEligibilityTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentSeasonalEligibilityTemplateAdjuster: SeasonalEligibilityTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSeasonalEligibilityTemplateAdjuster: SeasonalEligibilityTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalEligibilityTemplateAdjuster: SeasonalEligibilityTemplateFactor {
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

        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalEligibilityTemplateAdjuster: SeasonalEligibilityTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalEligibilityTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal eligibility template steps in order and keeps a trace of each.
    final class SeasonalEligibilityTemplateEngine {
        var steps: [any SeasonalEligibilityTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalEligibilityTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalEligibilityTemplate) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [SeasonalEligibilityTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalEligibilityTemplateEngine(_ flags: Kit.Flags.Registry) -> SeasonalEligibilityTemplateEngine {
        return SeasonalEligibilityTemplateEngine(
            steps: [
                SeasonalEligibilityTemplateAmountOffsetAdjuster(weight: 1.92),
                PercentSeasonalEligibilityTemplateAdjuster(percent: 2.8),
                SegmentSeasonalEligibilityTemplateAdjuster(factors: ["east": 1.32, "online": 0.7]),
                RoundingSeasonalEligibilityTemplateAdjuster(step: 0.05),
                FlaggedSeasonalEligibilityTemplateAdjuster(
                    flags: flags,
                    flag: "seasonal-eligibility-template-capped",
                    percent: 5.2
                ),
                CapSeasonalEligibilityTemplateAdjuster(cap: 42201.0),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 7029.0
        )
    }
}
