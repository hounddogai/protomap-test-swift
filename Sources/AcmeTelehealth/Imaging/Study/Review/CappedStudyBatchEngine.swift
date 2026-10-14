import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped study batch calculation.
    protocol CappedStudyBatchAdjuster {
        func describe() -> String
        func adjust(_ item: CappedStudyBatch, value: Double) -> Double
    }

    final class NameCappedStudyBatchAdjuster: CappedStudyBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedStudyBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedStudyBatchAdjuster: CappedStudyBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedStudyBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedStudyBatchAdjuster: CappedStudyBatchAdjuster {
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

        func adjust(_ item: CappedStudyBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped study batch steps in order and keeps a trace of each.
    final class CappedStudyBatchEngine {
        var steps: [any CappedStudyBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedStudyBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedStudyBatch) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CappedStudyBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedStudyBatchEngine(_ flags: Kit.Flags.Registry) -> CappedStudyBatchEngine {
        return CappedStudyBatchEngine(
            steps: [
                NameCappedStudyBatchAdjuster(factors: ["south": 1.02, "central": 0.73, "north": 1.29]),
                RoundingCappedStudyBatchAdjuster(step: 0.05),
                FlaggedCappedStudyBatchAdjuster(flags: flags, flag: "capped-study-batch-weighted", percent: -5.9),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 80091.0
        )
    }
}
