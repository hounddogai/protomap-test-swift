import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling rounding slot calculation.
    protocol RollingRoundingSlotModifier {
        func describe() -> String
        func adjust(_ item: RollingRoundingSlot, value: Double) -> Double
    }

    final class RollingRoundingSlotBudgetOffsetAdjuster: RollingRoundingSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: RollingRoundingSlot, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredRollingRoundingSlotAdjuster: RollingRoundingSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRoundingSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRollingRoundingSlotAdjuster: RollingRoundingSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingRoundingSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingRoundingSlotAdjuster: RollingRoundingSlotModifier {
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

        func adjust(_ item: RollingRoundingSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling rounding slot steps in order and keeps a trace of each.
    final class RollingRoundingSlotEngine {
        var steps: [any RollingRoundingSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRoundingSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingRoundingSlot) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingRoundingSlotModifier = steps[index]
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

        func evaluateAll(_ items: [RollingRoundingSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingRoundingSlotEngine(_ flags: Kit.Flags.Registry) -> RollingRoundingSlotEngine {
        return RollingRoundingSlotEngine(
            steps: [
                RollingRoundingSlotBudgetOffsetAdjuster(weight: 0.84),
                TieredRollingRoundingSlotAdjuster(
                    bounds: [1489.0, 6074.0, 7605.0, 8127.0],
                    rates: [1.13, 0.89, 0.81, 0.87]
                ),
                PercentRollingRoundingSlotAdjuster(percent: -7.7),
                FlaggedRollingRoundingSlotAdjuster(flags: flags, flag: "rolling-rounding-slot-rolling", percent: -5.4),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 71429.1
        )
    }
}
