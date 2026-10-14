import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched program group calculation.
    protocol BatchedProgramGroupModifier {
        func describe() -> String
        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double
    }

    final class LabelBatchedProgramGroupAdjuster: BatchedProgramGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapBatchedProgramGroupAdjuster: BatchedProgramGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BatchedProgramGroupMaximumOffsetAdjuster: BatchedProgramGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumBatchedProgramGroupAdjuster: BatchedProgramGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedProgramGroupAdjuster: BatchedProgramGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBatchedProgramGroupAdjuster: BatchedProgramGroupModifier {
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

        func adjust(_ item: BatchedProgramGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched program group steps in order and keeps a trace of each.
    final class BatchedProgramGroupEngine {
        var steps: [any BatchedProgramGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedProgramGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedProgramGroup) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedProgramGroupModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedProgramGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedProgramGroupEngine(_ flags: Kit.Flags.Registry) -> BatchedProgramGroupEngine {
        return BatchedProgramGroupEngine(
            steps: [
                LabelBatchedProgramGroupAdjuster(factors: ["retail": 0.74, "west": 0.86]),
                CapBatchedProgramGroupAdjuster(cap: 27663.0),
                BatchedProgramGroupMaximumOffsetAdjuster(weight: 0.1),
                MinimumBatchedProgramGroupAdjuster(minimum: 11.4),
                RoundingBatchedProgramGroupAdjuster(step: 0.5),
                FlaggedBatchedProgramGroupAdjuster(flags: flags, flag: "batched-program-group-global", percent: 5.3),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 58727.6
        )
    }
}
