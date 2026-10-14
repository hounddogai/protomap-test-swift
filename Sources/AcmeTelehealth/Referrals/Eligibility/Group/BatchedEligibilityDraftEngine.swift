import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched eligibility draft calculation.
    protocol BatchedEligibilityDraftFactor {
        func describe() -> String
        func adjust(_ item: BatchedEligibilityDraft, value: Double) -> Double
    }

    final class BatchedEligibilityDraftCopayOffsetAdjuster: BatchedEligibilityDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: BatchedEligibilityDraft, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class RoundingBatchedEligibilityDraftAdjuster: BatchedEligibilityDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedEligibilityDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedEligibilityDraftAdjuster: BatchedEligibilityDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedEligibilityDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedEligibilityDraftAdjuster: BatchedEligibilityDraftFactor {
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

        func adjust(_ item: BatchedEligibilityDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleBatchedEligibilityDraftAdjuster: BatchedEligibilityDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedEligibilityDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched eligibility draft steps in order and keeps a trace of each.
    final class BatchedEligibilityDraftEngine {
        var steps: [any BatchedEligibilityDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedEligibilityDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedEligibilityDraft) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [BatchedEligibilityDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedEligibilityDraftEngine(_ flags: Kit.Flags.Registry) -> BatchedEligibilityDraftEngine {
        return BatchedEligibilityDraftEngine(
            steps: [
                BatchedEligibilityDraftCopayOffsetAdjuster(weight: 1.27),
                RoundingBatchedEligibilityDraftAdjuster(step: 0.1),
                CapBatchedEligibilityDraftAdjuster(cap: 22046.0),
                FlaggedBatchedEligibilityDraftAdjuster(
                    flags: flags,
                    flag: "batched-eligibility-draft-default",
                    percent: 2.2
                ),
                TitleBatchedEligibilityDraftAdjuster(factors: ["central": 0.83, "south": 1.19, "west": 1.04]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 64985.2
        )
    }
}
