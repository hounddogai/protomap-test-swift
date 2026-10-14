import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy consent form request calculation.
    protocol LegacyConsentFormRequestFactor {
        func describe() -> String
        func adjust(_ item: LegacyConsentFormRequest, value: Double) -> Double
    }

    final class CapLegacyConsentFormRequestAdjuster: LegacyConsentFormRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyConsentFormRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyConsentFormRequestAdjuster: LegacyConsentFormRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyConsentFormRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyConsentFormRequestAdjuster: LegacyConsentFormRequestFactor {
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

        func adjust(_ item: LegacyConsentFormRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLegacyConsentFormRequestAdjuster: LegacyConsentFormRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyConsentFormRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy consent form request steps in order and keeps a trace of each.
    final class LegacyConsentFormRequestEngine {
        var steps: [any LegacyConsentFormRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyConsentFormRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyConsentFormRequest) -> Double {
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

        func evaluateAll(_ items: [LegacyConsentFormRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyConsentFormRequestEngine(_ flags: Kit.Flags.Registry) -> LegacyConsentFormRequestEngine {
        return LegacyConsentFormRequestEngine(
            steps: [
                CapLegacyConsentFormRequestAdjuster(cap: 21129.0),
                MinimumLegacyConsentFormRequestAdjuster(minimum: 38.4),
                FlaggedLegacyConsentFormRequestAdjuster(
                    flags: flags,
                    flag: "legacy-consent-form-request-lenient",
                    percent: -9.1
                ),
                PercentLegacyConsentFormRequestAdjuster(percent: -12.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 7690.9
        )
    }
}
