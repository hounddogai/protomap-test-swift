import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional consent form quota calculation.
    protocol RegionalConsentFormQuotaModifier {
        func describe() -> String
        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double
    }

    final class CapRegionalConsentFormQuotaAdjuster: RegionalConsentFormQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalConsentFormQuotaAdjuster: RegionalConsentFormQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleRegionalConsentFormQuotaAdjuster: RegionalConsentFormQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalConsentFormQuotaAdjuster: RegionalConsentFormQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalConsentFormQuotaAdjuster: RegionalConsentFormQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRegionalConsentFormQuotaAdjuster: RegionalConsentFormQuotaModifier {
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

        func adjust(_ item: RegionalConsentFormQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional consent form quota steps in order and keeps a trace of each.
    final class RegionalConsentFormQuotaEngine {
        var steps: [any RegionalConsentFormQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalConsentFormQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalConsentFormQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalConsentFormQuotaModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RegionalConsentFormQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalConsentFormQuotaEngine(_ flags: Kit.Flags.Registry) -> RegionalConsentFormQuotaEngine {
        return RegionalConsentFormQuotaEngine(
            steps: [
                CapRegionalConsentFormQuotaAdjuster(cap: 38344.0),
                RoundingRegionalConsentFormQuotaAdjuster(step: 1.0),
                TitleRegionalConsentFormQuotaAdjuster(factors: ["online": 1.2, "retail": 1.36, "west": 1.0]),
                MinimumRegionalConsentFormQuotaAdjuster(minimum: 43.9),
                TieredRegionalConsentFormQuotaAdjuster(bounds: [7064.0, 8308.0], rates: [0.93, 0.83]),
                FlaggedRegionalConsentFormQuotaAdjuster(
                    flags: flags,
                    flag: "regional-consent-form-quota-capped",
                    percent: 1.1
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 63926.3
        )
    }
}
