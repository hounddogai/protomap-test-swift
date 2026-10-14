import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched cleaning cycle calculation.
    protocol BatchedCleaningCycleAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedCleaningCycle, value: Double) -> Double
    }

    final class FlaggedBatchedCleaningCycleAdjuster: BatchedCleaningCycleAdjuster {
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

        func adjust(_ item: BatchedCleaningCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedCleaningCycleAdjuster: BatchedCleaningCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedCleaningCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BatchedCleaningCyclePriorityOffsetAdjuster: BatchedCleaningCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: BatchedCleaningCycle, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class TieredBatchedCleaningCycleAdjuster: BatchedCleaningCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCleaningCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapBatchedCleaningCycleAdjuster: BatchedCleaningCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCleaningCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched cleaning cycle steps in order and keeps a trace of each.
    final class BatchedCleaningCycleEngine {
        var steps: [any BatchedCleaningCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCleaningCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCleaningCycle) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedCleaningCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedCleaningCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCleaningCycleEngine(_ flags: Kit.Flags.Registry) -> BatchedCleaningCycleEngine {
        return BatchedCleaningCycleEngine(
            steps: [
                FlaggedBatchedCleaningCycleAdjuster(flags: flags, flag: "batched-cleaning-cycle-manual", percent: 3.9),
                MinimumBatchedCleaningCycleAdjuster(minimum: 32.1),
                BatchedCleaningCyclePriorityOffsetAdjuster(weight: 1.8),
                TieredBatchedCleaningCycleAdjuster(bounds: [3402.0, 9913.0], rates: [0.99, 0.87]),
                CapBatchedCleaningCycleAdjuster(cap: 19680.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 68473.0
        )
    }
}
