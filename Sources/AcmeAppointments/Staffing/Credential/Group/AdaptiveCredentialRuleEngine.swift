import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive credential rule calculation.
    protocol AdaptiveCredentialRuleAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double
    }

    final class TieredAdaptiveCredentialRuleAdjuster: AdaptiveCredentialRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveCredentialRuleAdjuster: AdaptiveCredentialRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveCredentialRuleAdjuster: AdaptiveCredentialRuleAdjuster {
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

        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveCredentialRuleAdjuster: AdaptiveCredentialRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveCredentialRuleCreatedAtOffsetAdjuster: AdaptiveCredentialRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class RoundingAdaptiveCredentialRuleAdjuster: AdaptiveCredentialRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveCredentialRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive credential rule steps in order and keeps a trace of each.
    final class AdaptiveCredentialRuleEngine {
        var steps: [any AdaptiveCredentialRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCredentialRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveCredentialRule) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [AdaptiveCredentialRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCredentialRuleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveCredentialRuleEngine {
        return AdaptiveCredentialRuleEngine(
            steps: [
                TieredAdaptiveCredentialRuleAdjuster(
                    bounds: [897.0, 4060.0, 4289.0, 8836.0],
                    rates: [0.89, 0.84, 1.03, 1.13]
                ),
                PercentAdaptiveCredentialRuleAdjuster(percent: -5.6),
                FlaggedAdaptiveCredentialRuleAdjuster(
                    flags: flags,
                    flag: "adaptive-credential-rule-seasonal",
                    percent: 9.7
                ),
                CapAdaptiveCredentialRuleAdjuster(cap: 29854.0),
                AdaptiveCredentialRuleCreatedAtOffsetAdjuster(weight: 1.81),
                RoundingAdaptiveCredentialRuleAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 60952.9
        )
    }
}
