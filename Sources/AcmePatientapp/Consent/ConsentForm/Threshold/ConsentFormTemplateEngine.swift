import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form template calculation.
    protocol ConsentFormTemplateStep {
        func describe() -> String
        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double
    }

    final class TieredConsentFormTemplateAdjuster: ConsentFormTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapConsentFormTemplateAdjuster: ConsentFormTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumConsentFormTemplateAdjuster: ConsentFormTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedConsentFormTemplateAdjuster: ConsentFormTemplateStep {
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

        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleConsentFormTemplateAdjuster: ConsentFormTemplateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingConsentFormTemplateAdjuster: ConsentFormTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form template steps in order and keeps a trace of each.
    final class ConsentFormTemplateEngine {
        var steps: [any ConsentFormTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormTemplate) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ConsentFormTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormTemplateEngine(_ flags: Kit.Flags.Registry) -> ConsentFormTemplateEngine {
        return ConsentFormTemplateEngine(
            steps: [
                TieredConsentFormTemplateAdjuster(bounds: [3671.0, 7337.0, 8176.0], rates: [1.0, 0.82, 0.99]),
                CapConsentFormTemplateAdjuster(cap: 45789.0),
                MinimumConsentFormTemplateAdjuster(minimum: 47.3),
                FlaggedConsentFormTemplateAdjuster(flags: flags, flag: "consent-form-template-capped", percent: 1.3),
                TitleConsentFormTemplateAdjuster(factors: ["online": 0.73, "central": 0.97]),
                RoundingConsentFormTemplateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 43157.7
        )
    }
}
