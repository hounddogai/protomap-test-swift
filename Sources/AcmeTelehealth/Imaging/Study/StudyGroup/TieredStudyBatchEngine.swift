import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered study batch calculation.
    protocol TieredStudyBatchModifier {
        func describe() -> String
        func adjust(_ item: TieredStudyBatch, value: Double) -> Double
    }

    final class RoundingTieredStudyBatchAdjuster: TieredStudyBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredStudyBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredStudyBatchAdjuster: TieredStudyBatchModifier {
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

        func adjust(_ item: TieredStudyBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredStudyBatchAdjuster: TieredStudyBatchModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredStudyBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredStudyBatchAdjuster: TieredStudyBatchModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredStudyBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredStudyBatchAdjuster: TieredStudyBatchModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredStudyBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered study batch steps in order and keeps a trace of each.
    final class TieredStudyBatchEngine {
        var steps: [any TieredStudyBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredStudyBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredStudyBatch) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredStudyBatchModifier = steps[index]
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

        func evaluateAll(_ items: [TieredStudyBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredStudyBatchEngine(_ flags: Kit.Flags.Registry) -> TieredStudyBatchEngine {
        return TieredStudyBatchEngine(
            steps: [
                RoundingTieredStudyBatchAdjuster(step: 0.25),
                FlaggedTieredStudyBatchAdjuster(flags: flags, flag: "tiered-study-batch-seasonal", percent: 3.3),
                MinimumTieredStudyBatchAdjuster(minimum: 36.3),
                PercentTieredStudyBatchAdjuster(percent: -17.7),
                TieredTieredStudyBatchAdjuster(bounds: [3119.0, 4135.0], rates: [0.99, 1.1]),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 76296.2
        )
    }
}
