import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted transfer slot calculation.
    protocol WeightedTransferSlotFactor {
        func describe() -> String
        func adjust(_ item: WeightedTransferSlot, value: Double) -> Double
    }

    final class FlaggedWeightedTransferSlotAdjuster: WeightedTransferSlotFactor {
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

        func adjust(_ item: WeightedTransferSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedTransferSlotAdjuster: WeightedTransferSlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedTransferSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedTransferSlotAdjuster: WeightedTransferSlotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedTransferSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameWeightedTransferSlotAdjuster: WeightedTransferSlotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedTransferSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedTransferSlotAdjuster: WeightedTransferSlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedTransferSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted transfer slot steps in order and keeps a trace of each.
    final class WeightedTransferSlotEngine {
        var steps: [any WeightedTransferSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTransferSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedTransferSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedTransferSlotFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedTransferSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedTransferSlotEngine(_ flags: Kit.Flags.Registry) -> WeightedTransferSlotEngine {
        return WeightedTransferSlotEngine(
            steps: [
                FlaggedWeightedTransferSlotAdjuster(
                    flags: flags,
                    flag: "weighted-transfer-slot-batched",
                    percent: -3.8
                ),
                PercentWeightedTransferSlotAdjuster(percent: -4.8),
                RoundingWeightedTransferSlotAdjuster(step: 0.5),
                NameWeightedTransferSlotAdjuster(factors: ["south": 0.74]),
                CapWeightedTransferSlotAdjuster(cap: 46556.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 37613.0
        )
    }
}
