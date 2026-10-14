import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility template calculation.
    protocol EligibilityTemplateStep {
        func describe() -> String
        func adjust(_ item: EligibilityTemplate, value: Double) -> Double
    }

    final class LabelEligibilityTemplateAdjuster: EligibilityTemplateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: EligibilityTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingEligibilityTemplateAdjuster: EligibilityTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapEligibilityTemplateAdjuster: EligibilityTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedEligibilityTemplateAdjuster: EligibilityTemplateStep {
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

        func adjust(_ item: EligibilityTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredEligibilityTemplateAdjuster: EligibilityTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentEligibilityTemplateAdjuster: EligibilityTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility template steps in order and keeps a trace of each.
    final class EligibilityTemplateEngine {
        var steps: [any EligibilityTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: EligibilityTemplate) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [EligibilityTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultEligibilityTemplateEngine(_ flags: Kit.Flags.Registry) -> EligibilityTemplateEngine {
        return EligibilityTemplateEngine(
            steps: [
                LabelEligibilityTemplateAdjuster(factors: ["south": 1.24, "online": 1.23, "central": 1.02]),
                RoundingEligibilityTemplateAdjuster(step: 0.05),
                CapEligibilityTemplateAdjuster(cap: 40184.0),
                FlaggedEligibilityTemplateAdjuster(flags: flags, flag: "eligibility-template-batched", percent: 5.2),
                TieredEligibilityTemplateAdjuster(bounds: [5578.0, 9169.0], rates: [1.13, 0.98]),
                PercentEligibilityTemplateAdjuster(percent: 18.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 79098.2
        )
    }
}
