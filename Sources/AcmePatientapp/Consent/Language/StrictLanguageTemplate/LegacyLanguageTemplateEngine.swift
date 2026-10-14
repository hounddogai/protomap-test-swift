import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy language template calculation.
    protocol LegacyLanguageTemplateFactor {
        func describe() -> String
        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double
    }

    final class FlaggedLegacyLanguageTemplateAdjuster: LegacyLanguageTemplateFactor {
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

        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyLanguageTemplateRefillsOffsetAdjuster: LegacyLanguageTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class LocaleLegacyLanguageTemplateAdjuster: LegacyLanguageTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyLanguageTemplateAdjuster: LegacyLanguageTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyLanguageTemplateAdjuster: LegacyLanguageTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyLanguageTemplateAdjuster: LegacyLanguageTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyLanguageTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy language template steps in order and keeps a trace of each.
    final class LegacyLanguageTemplateEngine {
        var steps: [any LegacyLanguageTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyLanguageTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyLanguageTemplate) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [LegacyLanguageTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyLanguageTemplateEngine(_ flags: Kit.Flags.Registry) -> LegacyLanguageTemplateEngine {
        return LegacyLanguageTemplateEngine(
            steps: [
                FlaggedLegacyLanguageTemplateAdjuster(
                    flags: flags,
                    flag: "legacy-language-template-tiered",
                    percent: -3.6
                ),
                LegacyLanguageTemplateRefillsOffsetAdjuster(weight: 1.51),
                LocaleLegacyLanguageTemplateAdjuster(factors: ["online": 1.05, "north": 0.74, "east": 1.05]),
                TieredLegacyLanguageTemplateAdjuster(bounds: [2029.0, 2243.0, 3478.0], rates: [1.07, 0.88, 1.12]),
                MinimumLegacyLanguageTemplateAdjuster(minimum: 4.7),
                PercentLegacyLanguageTemplateAdjuster(percent: 20.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 18846.0
        )
    }
}
