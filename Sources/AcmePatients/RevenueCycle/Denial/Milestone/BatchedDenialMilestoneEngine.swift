import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched denial milestone calculation.
    protocol BatchedDenialMilestoneModifier {
        func describe() -> String
        func adjust(_ item: BatchedDenialMilestone, value: Double) -> Double
    }

    final class FlaggedBatchedDenialMilestoneAdjuster: BatchedDenialMilestoneModifier {
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

        func adjust(_ item: BatchedDenialMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedDenialMilestoneAdjuster: BatchedDenialMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDenialMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedDenialMilestoneSequenceOffsetAdjuster: BatchedDenialMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: BatchedDenialMilestone, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TieredBatchedDenialMilestoneAdjuster: BatchedDenialMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedDenialMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched denial milestone steps in order and keeps a trace of each.
    final class BatchedDenialMilestoneEngine {
        var steps: [any BatchedDenialMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDenialMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedDenialMilestone) -> Double {
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

        func evaluateAll(_ items: [BatchedDenialMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedDenialMilestoneEngine(_ flags: Kit.Flags.Registry) -> BatchedDenialMilestoneEngine {
        return BatchedDenialMilestoneEngine(
            steps: [
                FlaggedBatchedDenialMilestoneAdjuster(
                    flags: flags,
                    flag: "batched-denial-milestone-global",
                    percent: -6.3
                ),
                RoundingBatchedDenialMilestoneAdjuster(step: 1.0),
                BatchedDenialMilestoneSequenceOffsetAdjuster(weight: 1.64),
                TieredBatchedDenialMilestoneAdjuster(bounds: [1600.0, 6824.0], rates: [0.96, 0.97]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 38287.6
        )
    }
}
