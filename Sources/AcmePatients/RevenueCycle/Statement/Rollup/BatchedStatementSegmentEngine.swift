import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched statement segment calculation.
    protocol BatchedStatementSegmentStep {
        func describe() -> String
        func adjust(_ item: BatchedStatementSegment, value: Double) -> Double
    }

    final class TieredBatchedStatementSegmentAdjuster: BatchedStatementSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedStatementSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedStatementSegmentAdjuster: BatchedStatementSegmentStep {
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

        func adjust(_ item: BatchedStatementSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentBatchedStatementSegmentAdjuster: BatchedStatementSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedStatementSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedStatementSegmentAdjuster: BatchedStatementSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedStatementSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedStatementSegmentAdjuster: BatchedStatementSegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStatementSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched statement segment steps in order and keeps a trace of each.
    final class BatchedStatementSegmentEngine {
        var steps: [any BatchedStatementSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStatementSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedStatementSegment) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedStatementSegmentStep = steps[index]
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

        func evaluateAll(_ items: [BatchedStatementSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedStatementSegmentEngine(_ flags: Kit.Flags.Registry) -> BatchedStatementSegmentEngine {
        return BatchedStatementSegmentEngine(
            steps: [
                TieredBatchedStatementSegmentAdjuster(bounds: [861.0, 4314.0], rates: [1.14, 0.9]),
                FlaggedBatchedStatementSegmentAdjuster(
                    flags: flags,
                    flag: "batched-statement-segment-regional",
                    percent: -0.6
                ),
                SegmentBatchedStatementSegmentAdjuster(factors: ["north": 0.91, "west": 1.28, "online": 0.77]),
                RoundingBatchedStatementSegmentAdjuster(step: 0.5),
                MinimumBatchedStatementSegmentAdjuster(minimum: 40.7),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 21527.2
        )
    }
}
