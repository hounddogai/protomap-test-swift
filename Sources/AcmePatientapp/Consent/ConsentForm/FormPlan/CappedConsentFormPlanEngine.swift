import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped consent form plan calculation.
    protocol CappedConsentFormPlanModifier {
        func describe() -> String
        func adjust(_ item: CappedConsentFormPlan, value: Double) -> Double
    }

    final class PercentCappedConsentFormPlanAdjuster: CappedConsentFormPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedConsentFormPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryCappedConsentFormPlanAdjuster: CappedConsentFormPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CappedConsentFormPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedConsentFormPlanAdjuster: CappedConsentFormPlanModifier {
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

        func adjust(_ item: CappedConsentFormPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped consent form plan steps in order and keeps a trace of each.
    final class CappedConsentFormPlanEngine {
        var steps: [any CappedConsentFormPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedConsentFormPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedConsentFormPlan) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedConsentFormPlanModifier = steps[index]
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

        func evaluateAll(_ items: [CappedConsentFormPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedConsentFormPlanEngine(_ flags: Kit.Flags.Registry) -> CappedConsentFormPlanEngine {
        return CappedConsentFormPlanEngine(
            steps: [
                PercentCappedConsentFormPlanAdjuster(percent: 5.0),
                CountryCappedConsentFormPlanAdjuster(factors: ["north": 1.1, "retail": 1.27]),
                FlaggedCappedConsentFormPlanAdjuster(
                    flags: flags,
                    flag: "capped-consent-form-plan-pending",
                    percent: -0.8
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 60438.6
        )
    }
}
