import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched accession preference calculation.
    protocol BatchedAccessionPreferenceModifier {
        func describe() -> String
        func adjust(_ item: BatchedAccessionPreference, value: Double) -> Double
    }

    final class LabelBatchedAccessionPreferenceAdjuster: BatchedAccessionPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedAccessionPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedAccessionPreferenceAdjuster: BatchedAccessionPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedAccessionPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedAccessionPreferenceAdjuster: BatchedAccessionPreferenceModifier {
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

        func adjust(_ item: BatchedAccessionPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched accession preference steps in order and keeps a trace of each.
    final class BatchedAccessionPreferenceEngine {
        var steps: [any BatchedAccessionPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAccessionPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedAccessionPreference) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedAccessionPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedAccessionPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedAccessionPreferenceEngine(_ flags: Kit.Flags.Registry) -> BatchedAccessionPreferenceEngine {
        return BatchedAccessionPreferenceEngine(
            steps: [
                LabelBatchedAccessionPreferenceAdjuster(factors: ["north": 1.32]),
                MinimumBatchedAccessionPreferenceAdjuster(minimum: 43.3),
                FlaggedBatchedAccessionPreferenceAdjuster(
                    flags: flags,
                    flag: "batched-accession-preference-pending",
                    percent: 3.3
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 87915.2
        )
    }
}
