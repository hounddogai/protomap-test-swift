import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy consent form plan calculation.
    protocol LegacyConsentFormPlanStep {
        func describe() -> String
        func adjust(_ item: LegacyConsentFormPlan, value: Double) -> Double
    }

    final class LegacyConsentFormPlanRetriesOffsetAdjuster: LegacyConsentFormPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: LegacyConsentFormPlan, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumLegacyConsentFormPlanAdjuster: LegacyConsentFormPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyConsentFormPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyConsentFormPlanAdjuster: LegacyConsentFormPlanStep {
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

        func adjust(_ item: LegacyConsentFormPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyConsentFormPlanAdjuster: LegacyConsentFormPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyConsentFormPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy consent form plan steps in order and keeps a trace of each.
    final class LegacyConsentFormPlanEngine {
        var steps: [any LegacyConsentFormPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyConsentFormPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyConsentFormPlan) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyConsentFormPlanStep = steps[index]
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

        func evaluateAll(_ items: [LegacyConsentFormPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyConsentFormPlanEngine(_ flags: Kit.Flags.Registry) -> LegacyConsentFormPlanEngine {
        return LegacyConsentFormPlanEngine(
            steps: [
                LegacyConsentFormPlanRetriesOffsetAdjuster(weight: 0.89),
                MinimumLegacyConsentFormPlanAdjuster(minimum: 21.6),
                FlaggedLegacyConsentFormPlanAdjuster(
                    flags: flags,
                    flag: "legacy-consent-form-plan-strict",
                    percent: -2.4
                ),
                RoundingLegacyConsentFormPlanAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 64683.3
        )
    }
}
