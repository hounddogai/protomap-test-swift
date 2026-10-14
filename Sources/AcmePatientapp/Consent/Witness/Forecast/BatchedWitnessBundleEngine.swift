import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched witness bundle calculation.
    protocol BatchedWitnessBundleAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedWitnessBundle, value: Double) -> Double
    }

    final class MinimumBatchedWitnessBundleAdjuster: BatchedWitnessBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedWitnessBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedWitnessBundleAdjuster: BatchedWitnessBundleAdjuster {
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

        func adjust(_ item: BatchedWitnessBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameBatchedWitnessBundleAdjuster: BatchedWitnessBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedWitnessBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched witness bundle steps in order and keeps a trace of each.
    final class BatchedWitnessBundleEngine {
        var steps: [any BatchedWitnessBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedWitnessBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedWitnessBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedWitnessBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedWitnessBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedWitnessBundleEngine(_ flags: Kit.Flags.Registry) -> BatchedWitnessBundleEngine {
        return BatchedWitnessBundleEngine(
            steps: [
                MinimumBatchedWitnessBundleAdjuster(minimum: 44.2),
                FlaggedBatchedWitnessBundleAdjuster(
                    flags: flags,
                    flag: "batched-witness-bundle-primary",
                    percent: 2.9
                ),
                NameBatchedWitnessBundleAdjuster(factors: ["south": 1.37, "retail": 0.71, "online": 0.87]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 24756.7
        )
    }
}
