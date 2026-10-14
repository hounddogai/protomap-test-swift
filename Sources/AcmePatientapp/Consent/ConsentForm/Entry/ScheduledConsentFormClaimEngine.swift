import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled consent form claim calculation.
    protocol ScheduledConsentFormClaimFactor {
        func describe() -> String
        func adjust(_ item: ScheduledConsentFormClaim, value: Double) -> Double
    }

    final class FlaggedScheduledConsentFormClaimAdjuster: ScheduledConsentFormClaimFactor {
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

        func adjust(_ item: ScheduledConsentFormClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledConsentFormClaimAdjuster: ScheduledConsentFormClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledConsentFormClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledConsentFormClaimAdjuster: ScheduledConsentFormClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledConsentFormClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleScheduledConsentFormClaimAdjuster: ScheduledConsentFormClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledConsentFormClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled consent form claim steps in order and keeps a trace of each.
    final class ScheduledConsentFormClaimEngine {
        var steps: [any ScheduledConsentFormClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledConsentFormClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledConsentFormClaim) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [ScheduledConsentFormClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledConsentFormClaimEngine(_ flags: Kit.Flags.Registry) -> ScheduledConsentFormClaimEngine {
        return ScheduledConsentFormClaimEngine(
            steps: [
                FlaggedScheduledConsentFormClaimAdjuster(
                    flags: flags,
                    flag: "scheduled-consent-form-claim-scheduled",
                    percent: 2.0
                ),
                PercentScheduledConsentFormClaimAdjuster(percent: -18.5),
                MinimumScheduledConsentFormClaimAdjuster(minimum: 2.9),
                TitleScheduledConsentFormClaimAdjuster(factors: ["central": 0.82, "north": 1.21]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 70461.1
        )
    }
}
