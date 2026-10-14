import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential rule calculation.
    protocol CredentialRuleAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialRule, value: Double) -> Double
    }

    final class PercentCredentialRuleAdjuster: CredentialRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialRuleAdjuster: CredentialRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCredentialRuleAdjuster: CredentialRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCredentialRuleAdjuster: CredentialRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleCredentialRuleAdjuster: CredentialRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CredentialRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCredentialRuleAdjuster: CredentialRuleAdjuster {
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

        func adjust(_ item: CredentialRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the credential rule steps in order and keeps a trace of each.
    final class CredentialRuleEngine {
        var steps: [any CredentialRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialRule) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [CredentialRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialRuleEngine(_ flags: Kit.Flags.Registry) -> CredentialRuleEngine {
        return CredentialRuleEngine(
            steps: [
                PercentCredentialRuleAdjuster(percent: 8.9),
                CapCredentialRuleAdjuster(cap: 19645.0),
                TieredCredentialRuleAdjuster(bounds: [6106.0, 6278.0, 6703.0], rates: [0.88, 1.15, 1.0]),
                MinimumCredentialRuleAdjuster(minimum: 20.8),
                LocaleCredentialRuleAdjuster(factors: ["south": 0.98, "north": 1.11]),
                FlaggedCredentialRuleAdjuster(flags: flags, flag: "credential-rule-weighted", percent: 8.5),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 71510.3
        )
    }
}
