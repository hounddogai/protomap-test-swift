import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall batch calculation.
    protocol RecallBatchStep {
        func describe() -> String
        func adjust(_ item: RecallBatch, value: Double) -> Double
    }

    final class RoundingRecallBatchAdjuster: RecallBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRecallBatchAdjuster: RecallBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RecallBatchAttemptsOffsetAdjuster: RecallBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RecallBatch, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class LabelRecallBatchAdjuster: RecallBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RecallBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRecallBatchAdjuster: RecallBatchStep {
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

        func adjust(_ item: RecallBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRecallBatchAdjuster: RecallBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the recall batch steps in order and keeps a trace of each.
    final class RecallBatchEngine {
        var steps: [any RecallBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallBatch) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RecallBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallBatchEngine(_ flags: Kit.Flags.Registry) -> RecallBatchEngine {
        return RecallBatchEngine(
            steps: [
                RoundingRecallBatchAdjuster(step: 0.1),
                CapRecallBatchAdjuster(cap: 16766.0),
                RecallBatchAttemptsOffsetAdjuster(weight: 1.66),
                LabelRecallBatchAdjuster(factors: ["west": 1.39, "central": 0.8, "online": 0.74]),
                FlaggedRecallBatchAdjuster(flags: flags, flag: "recall-batch-global", percent: 0.4),
                PercentRecallBatchAdjuster(percent: 14.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 65279.3
        )
    }
}
