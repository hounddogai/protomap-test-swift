import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan checkpoint calculation.
    protocol DischargePlanCheckpointModifier {
        func describe() -> String
        func adjust(_ item: DischargePlanCheckpoint, value: Double) -> Double
    }

    final class TieredDischargePlanCheckpointAdjuster: DischargePlanCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DischargePlanCheckpointQuantityOffsetAdjuster: DischargePlanCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DischargePlanCheckpoint, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedDischargePlanCheckpointAdjuster: DischargePlanCheckpointModifier {
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

        func adjust(_ item: DischargePlanCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDischargePlanCheckpointAdjuster: DischargePlanCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the discharge plan checkpoint steps in order and keeps a trace of each.
    final class DischargePlanCheckpointEngine {
        var steps: [any DischargePlanCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DischargePlanCheckpoint) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [DischargePlanCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDischargePlanCheckpointEngine(_ flags: Kit.Flags.Registry) -> DischargePlanCheckpointEngine {
        return DischargePlanCheckpointEngine(
            steps: [
                TieredDischargePlanCheckpointAdjuster(
                    bounds: [1393.0, 1555.0, 6378.0, 8229.0],
                    rates: [1.13, 1.1, 0.91, 1.08]
                ),
                DischargePlanCheckpointQuantityOffsetAdjuster(weight: 1.96),
                FlaggedDischargePlanCheckpointAdjuster(
                    flags: flags,
                    flag: "discharge-plan-checkpoint-tiered",
                    percent: -3.2
                ),
                CapDischargePlanCheckpointAdjuster(cap: 8357.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 79653.6
        )
    }
}
