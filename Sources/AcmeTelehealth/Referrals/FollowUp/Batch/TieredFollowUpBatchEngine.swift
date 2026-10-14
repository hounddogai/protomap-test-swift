import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered follow up batch calculation.
    protocol TieredFollowUpBatchStep {
        func describe() -> String
        func adjust(_ item: TieredFollowUpBatch, value: Double) -> Double
    }

    final class FlaggedTieredFollowUpBatchAdjuster: TieredFollowUpBatchStep {
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

        func adjust(_ item: TieredFollowUpBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredFollowUpBatchAdjuster: TieredFollowUpBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFollowUpBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredFollowUpBatchAdjuster: TieredFollowUpBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredFollowUpBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFollowUpBatchFloorValueOffsetAdjuster: TieredFollowUpBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: TieredFollowUpBatch, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredTieredFollowUpBatchAdjuster: TieredFollowUpBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredFollowUpBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered follow up batch steps in order and keeps a trace of each.
    final class TieredFollowUpBatchEngine {
        var steps: [any TieredFollowUpBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredFollowUpBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredFollowUpBatch) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredFollowUpBatchStep = steps[index]
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

        func evaluateAll(_ items: [TieredFollowUpBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredFollowUpBatchEngine(_ flags: Kit.Flags.Registry) -> TieredFollowUpBatchEngine {
        return TieredFollowUpBatchEngine(
            steps: [
                FlaggedTieredFollowUpBatchAdjuster(
                    flags: flags,
                    flag: "tiered-follow-up-batch-adaptive",
                    percent: 9.0
                ),
                CapTieredFollowUpBatchAdjuster(cap: 8845.0),
                RoundingTieredFollowUpBatchAdjuster(step: 0.05),
                TieredFollowUpBatchFloorValueOffsetAdjuster(weight: 0.69),
                TieredTieredFollowUpBatchAdjuster(bounds: [2179.0, 2792.0], rates: [1.15, 0.99]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 32411.3
        )
    }
}
