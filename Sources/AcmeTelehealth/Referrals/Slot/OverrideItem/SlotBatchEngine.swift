import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot batch calculation.
    protocol SlotBatchAdjuster {
        func describe() -> String
        func adjust(_ item: SlotBatch, value: Double) -> Double
    }

    final class SlotBatchFloorValueOffsetAdjuster: SlotBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: SlotBatch, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingSlotBatchAdjuster: SlotBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceSlotBatchAdjuster: SlotBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SlotBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSlotBatchAdjuster: SlotBatchAdjuster {
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

        func adjust(_ item: SlotBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot batch steps in order and keeps a trace of each.
    final class SlotBatchEngine {
        var steps: [any SlotBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotBatch) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [SlotBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotBatchEngine(_ flags: Kit.Flags.Registry) -> SlotBatchEngine {
        return SlotBatchEngine(
            steps: [
                SlotBatchFloorValueOffsetAdjuster(weight: 1.38),
                RoundingSlotBatchAdjuster(step: 0.25),
                SourceSlotBatchAdjuster(factors: ["central": 1.02]),
                FlaggedSlotBatchAdjuster(flags: flags, flag: "slot-batch-default", percent: 8.4),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 77578.6
        )
    }
}
