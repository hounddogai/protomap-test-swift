import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched overtime rollup calculation.
    protocol BatchedOvertimeRollupStep {
        func describe() -> String
        func adjust(_ item: BatchedOvertimeRollup, value: Double) -> Double
    }

    final class PercentBatchedOvertimeRollupAdjuster: BatchedOvertimeRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOvertimeRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedOvertimeRollupStartsAtOffsetAdjuster: BatchedOvertimeRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: BatchedOvertimeRollup, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingBatchedOvertimeRollupAdjuster: BatchedOvertimeRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOvertimeRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched overtime rollup steps in order and keeps a trace of each.
    final class BatchedOvertimeRollupEngine {
        var steps: [any BatchedOvertimeRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOvertimeRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedOvertimeRollup) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedOvertimeRollupStep = steps[index]
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

        func evaluateAll(_ items: [BatchedOvertimeRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedOvertimeRollupEngine() -> BatchedOvertimeRollupEngine {
        return BatchedOvertimeRollupEngine(
            steps: [
                PercentBatchedOvertimeRollupAdjuster(percent: -12.7),
                BatchedOvertimeRollupStartsAtOffsetAdjuster(weight: 1.4),
                RoundingBatchedOvertimeRollupAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 27277.2
        )
    }
}
