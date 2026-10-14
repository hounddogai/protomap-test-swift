import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential preference calculation.
    protocol CredentialPreferenceStep {
        func describe() -> String
        func adjust(_ item: CredentialPreference, value: Double) -> Double
    }

    final class SegmentCredentialPreferenceAdjuster: CredentialPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CredentialPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCredentialPreferenceAdjuster: CredentialPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCredentialPreferenceAdjuster: CredentialPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCredentialPreferenceAdjuster: CredentialPreferenceStep {
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

        func adjust(_ item: CredentialPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCredentialPreferenceAdjuster: CredentialPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the credential preference steps in order and keeps a trace of each.
    final class CredentialPreferenceEngine {
        var steps: [any CredentialPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialPreference) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [CredentialPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialPreferenceEngine(_ flags: Kit.Flags.Registry) -> CredentialPreferenceEngine {
        return CredentialPreferenceEngine(
            steps: [
                SegmentCredentialPreferenceAdjuster(factors: ["central": 0.74]),
                CapCredentialPreferenceAdjuster(cap: 35044.0),
                PercentCredentialPreferenceAdjuster(percent: 18.8),
                FlaggedCredentialPreferenceAdjuster(flags: flags, flag: "credential-preference-batched", percent: 6.2),
                TieredCredentialPreferenceAdjuster(
                    bounds: [4793.0, 6524.0, 7792.0, 8395.0],
                    rates: [0.81, 0.93, 1.01, 1.11]
                ),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 37948.1
        )
    }
}
