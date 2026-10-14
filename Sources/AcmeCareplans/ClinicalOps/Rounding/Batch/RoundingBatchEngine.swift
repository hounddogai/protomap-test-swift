import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding batch calculation.
    protocol RoundingBatchStep {
        func describe() -> String
        func adjust(_ item: RoundingBatch, value: Double) -> Double
    }

    final class TieredRoundingBatchAdjuster: RoundingBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRoundingBatchAdjuster: RoundingBatchStep {
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

        func adjust(_ item: RoundingBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRoundingBatchAdjuster: RoundingBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rounding batch steps in order and keeps a trace of each.
    final class RoundingBatchEngine {
        var steps: [any RoundingBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RoundingBatch) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingBatchStep = steps[index]
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

        func evaluateAll(_ items: [RoundingBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRoundingBatchEngine(_ flags: Kit.Flags.Registry) -> RoundingBatchEngine {
        return RoundingBatchEngine(
            steps: [
                TieredRoundingBatchAdjuster(bounds: [944.0, 1342.0, 7755.0], rates: [0.87, 1.06, 1.17]),
                FlaggedRoundingBatchAdjuster(flags: flags, flag: "rounding-batch-tiered", percent: -5.8),
                PercentRoundingBatchAdjuster(percent: 13.4),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 27132.9
        )
    }
}
