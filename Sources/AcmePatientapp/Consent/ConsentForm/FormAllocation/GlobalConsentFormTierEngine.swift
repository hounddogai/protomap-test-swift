import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global consent form tier calculation.
    protocol GlobalConsentFormTierAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalConsentFormTier, value: Double) -> Double
    }

    final class FlaggedGlobalConsentFormTierAdjuster: GlobalConsentFormTierAdjuster {
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

        func adjust(_ item: GlobalConsentFormTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalConsentFormTierAdjuster: GlobalConsentFormTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalConsentFormTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalConsentFormTierRateOffsetAdjuster: GlobalConsentFormTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: GlobalConsentFormTier, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumGlobalConsentFormTierAdjuster: GlobalConsentFormTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalConsentFormTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalConsentFormTierAdjuster: GlobalConsentFormTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalConsentFormTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global consent form tier steps in order and keeps a trace of each.
    final class GlobalConsentFormTierEngine {
        var steps: [any GlobalConsentFormTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalConsentFormTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalConsentFormTier) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [GlobalConsentFormTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalConsentFormTierEngine(_ flags: Kit.Flags.Registry) -> GlobalConsentFormTierEngine {
        return GlobalConsentFormTierEngine(
            steps: [
                FlaggedGlobalConsentFormTierAdjuster(
                    flags: flags,
                    flag: "global-consent-form-tier-manual",
                    percent: 5.0
                ),
                CapGlobalConsentFormTierAdjuster(cap: 48723.0),
                GlobalConsentFormTierRateOffsetAdjuster(weight: 0.76),
                MinimumGlobalConsentFormTierAdjuster(minimum: 25.4),
                PercentGlobalConsentFormTierAdjuster(percent: 7.3),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 3140.3
        )
    }
}
