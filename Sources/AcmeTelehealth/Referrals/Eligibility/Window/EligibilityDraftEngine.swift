import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility draft calculation.
    protocol EligibilityDraftAdjuster {
        func describe() -> String
        func adjust(_ item: EligibilityDraft, value: Double) -> Double
    }

    final class FlaggedEligibilityDraftAdjuster: EligibilityDraftAdjuster {
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

        func adjust(_ item: EligibilityDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentEligibilityDraftAdjuster: EligibilityDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryEligibilityDraftAdjuster: EligibilityDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: EligibilityDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility draft steps in order and keeps a trace of each.
    final class EligibilityDraftEngine {
        var steps: [any EligibilityDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityDraft) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [EligibilityDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityDraftEngine(_ flags: Kit.Flags.Registry) -> EligibilityDraftEngine {
        return EligibilityDraftEngine(
            steps: [
                FlaggedEligibilityDraftAdjuster(flags: flags, flag: "eligibility-draft-legacy", percent: -0.4),
                PercentEligibilityDraftAdjuster(percent: -3.1),
                CategoryEligibilityDraftAdjuster(factors: ["central": 1.3, "retail": 0.94]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 80924.7
        )
    }
}
