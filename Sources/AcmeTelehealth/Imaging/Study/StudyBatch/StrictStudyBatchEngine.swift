import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict study batch calculation.
    protocol StrictStudyBatchAdjuster {
        func describe() -> String
        func adjust(_ item: StrictStudyBatch, value: Double) -> Double
    }

    final class StrictStudyBatchDosageMgOffsetAdjuster: StrictStudyBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: StrictStudyBatch, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class FlaggedStrictStudyBatchAdjuster: StrictStudyBatchAdjuster {
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

        func adjust(_ item: StrictStudyBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictStudyBatchAdjuster: StrictStudyBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictStudyBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStrictStudyBatchAdjuster: StrictStudyBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictStudyBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict study batch steps in order and keeps a trace of each.
    final class StrictStudyBatchEngine {
        var steps: [any StrictStudyBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictStudyBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictStudyBatch) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [StrictStudyBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictStudyBatchEngine(_ flags: Kit.Flags.Registry) -> StrictStudyBatchEngine {
        return StrictStudyBatchEngine(
            steps: [
                StrictStudyBatchDosageMgOffsetAdjuster(weight: 0.92),
                FlaggedStrictStudyBatchAdjuster(flags: flags, flag: "strict-study-batch-pending", percent: 0.4),
                RoundingStrictStudyBatchAdjuster(step: 0.05),
                PercentStrictStudyBatchAdjuster(percent: -22.7),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 83460.9
        )
    }
}
