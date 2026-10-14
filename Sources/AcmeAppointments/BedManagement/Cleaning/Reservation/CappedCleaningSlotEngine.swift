import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped cleaning slot calculation.
    protocol CappedCleaningSlotStep {
        func describe() -> String
        func adjust(_ item: CappedCleaningSlot, value: Double) -> Double
    }

    final class CappedCleaningSlotWeightOffsetAdjuster: CappedCleaningSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CappedCleaningSlot, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class RoundingCappedCleaningSlotAdjuster: CappedCleaningSlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCleaningSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedCleaningSlotAdjuster: CappedCleaningSlotStep {
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

        func adjust(_ item: CappedCleaningSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedCleaningSlotAdjuster: CappedCleaningSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCleaningSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelCappedCleaningSlotAdjuster: CappedCleaningSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedCleaningSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped cleaning slot steps in order and keeps a trace of each.
    final class CappedCleaningSlotEngine {
        var steps: [any CappedCleaningSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCleaningSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedCleaningSlot) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCleaningSlotStep = steps[index]
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

        func evaluateAll(_ items: [CappedCleaningSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedCleaningSlotEngine(_ flags: Kit.Flags.Registry) -> CappedCleaningSlotEngine {
        return CappedCleaningSlotEngine(
            steps: [
                CappedCleaningSlotWeightOffsetAdjuster(weight: 1.1),
                RoundingCappedCleaningSlotAdjuster(step: 1.0),
                FlaggedCappedCleaningSlotAdjuster(flags: flags, flag: "capped-cleaning-slot-default", percent: 8.1),
                MinimumCappedCleaningSlotAdjuster(minimum: 48.4),
                LabelCappedCleaningSlotAdjuster(factors: ["north": 1.32]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 21624.6
        )
    }
}
