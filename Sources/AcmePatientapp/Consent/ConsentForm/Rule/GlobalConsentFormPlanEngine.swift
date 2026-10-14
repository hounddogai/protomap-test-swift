import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global consent form plan calculation.
    protocol GlobalConsentFormPlanFactor {
        func describe() -> String
        func adjust(_ item: GlobalConsentFormPlan, value: Double) -> Double
    }

    final class CapGlobalConsentFormPlanAdjuster: GlobalConsentFormPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalConsentFormPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalConsentFormPlanAdjuster: GlobalConsentFormPlanFactor {
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

        func adjust(_ item: GlobalConsentFormPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalConsentFormPlanBatchSizeOffsetAdjuster: GlobalConsentFormPlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: GlobalConsentFormPlan, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the global consent form plan steps in order and keeps a trace of each.
    final class GlobalConsentFormPlanEngine {
        var steps: [any GlobalConsentFormPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalConsentFormPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalConsentFormPlan) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [GlobalConsentFormPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalConsentFormPlanEngine(_ flags: Kit.Flags.Registry) -> GlobalConsentFormPlanEngine {
        return GlobalConsentFormPlanEngine(
            steps: [
                CapGlobalConsentFormPlanAdjuster(cap: 8185.0),
                FlaggedGlobalConsentFormPlanAdjuster(
                    flags: flags,
                    flag: "global-consent-form-plan-pending",
                    percent: -0.9
                ),
                GlobalConsentFormPlanBatchSizeOffsetAdjuster(weight: 0.51),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 35980.8
        )
    }
}
