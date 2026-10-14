import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority batch calculation.
    protocol PriorityBatchStep {
        func describe() -> String
        func adjust(_ item: PriorityBatch, value: Double) -> Double
    }

    final class RoundingPriorityBatchAdjuster: PriorityBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PriorityBatchScoreOffsetAdjuster: PriorityBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: PriorityBatch, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedPriorityBatchAdjuster: PriorityBatchStep {
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

        func adjust(_ item: PriorityBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPriorityBatchAdjuster: PriorityBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPriorityBatchAdjuster: PriorityBatchStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the priority batch steps in order and keeps a trace of each.
    final class PriorityBatchEngine {
        var steps: [any PriorityBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PriorityBatch) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityBatchStep = steps[index]
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

        func evaluateAll(_ items: [PriorityBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPriorityBatchEngine(_ flags: Kit.Flags.Registry) -> PriorityBatchEngine {
        return PriorityBatchEngine(
            steps: [
                RoundingPriorityBatchAdjuster(step: 0.1),
                PriorityBatchScoreOffsetAdjuster(weight: 1.55),
                FlaggedPriorityBatchAdjuster(flags: flags, flag: "priority-batch-manual", percent: 9.8),
                TieredPriorityBatchAdjuster(bounds: [1307.0, 4782.0, 5349.0, 6696.0], rates: [1.11, 1.02, 0.93, 1.17]),
                MinimumPriorityBatchAdjuster(minimum: 48.5),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 67414.2
        )
    }
}
