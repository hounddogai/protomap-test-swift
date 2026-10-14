import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched census agreement calculation.
    protocol BatchedCensusAgreementFactor {
        func describe() -> String
        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double
    }

    final class BatchedCensusAgreementDosageMgOffsetAdjuster: BatchedCensusAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentBatchedCensusAgreementAdjuster: BatchedCensusAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedCensusAgreementAdjuster: BatchedCensusAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBatchedCensusAgreementAdjuster: BatchedCensusAgreementFactor {
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

        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedCensusAgreementAdjuster: BatchedCensusAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityBatchedCensusAgreementAdjuster: BatchedCensusAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BatchedCensusAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched census agreement steps in order and keeps a trace of each.
    final class BatchedCensusAgreementEngine {
        var steps: [any BatchedCensusAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCensusAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCensusAgreement) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedCensusAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedCensusAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCensusAgreementEngine(_ flags: Kit.Flags.Registry) -> BatchedCensusAgreementEngine {
        return BatchedCensusAgreementEngine(
            steps: [
                BatchedCensusAgreementDosageMgOffsetAdjuster(weight: 1.38),
                PercentBatchedCensusAgreementAdjuster(percent: -24.7),
                RoundingBatchedCensusAgreementAdjuster(step: 0.05),
                FlaggedBatchedCensusAgreementAdjuster(
                    flags: flags,
                    flag: "batched-census-agreement-pending",
                    percent: -8.9
                ),
                MinimumBatchedCensusAgreementAdjuster(minimum: 10.2),
                FacilityBatchedCensusAgreementAdjuster(factors: ["north": 1.02, "retail": 0.89]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 19719.4
        )
    }
}
