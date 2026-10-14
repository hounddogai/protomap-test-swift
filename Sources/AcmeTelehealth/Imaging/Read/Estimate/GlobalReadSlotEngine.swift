import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global read slot calculation.
    protocol GlobalReadSlotModifier {
        func describe() -> String
        func adjust(_ item: GlobalReadSlot, value: Double) -> Double
    }

    final class MinimumGlobalReadSlotAdjuster: GlobalReadSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalReadSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalReadSlotAdjuster: GlobalReadSlotModifier {
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

        func adjust(_ item: GlobalReadSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentGlobalReadSlotAdjuster: GlobalReadSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GlobalReadSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGlobalReadSlotAdjuster: GlobalReadSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalReadSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalReadSlotDiscountOffsetAdjuster: GlobalReadSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: GlobalReadSlot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the global read slot steps in order and keeps a trace of each.
    final class GlobalReadSlotEngine {
        var steps: [any GlobalReadSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReadSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalReadSlot) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalReadSlotModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalReadSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalReadSlotEngine(_ flags: Kit.Flags.Registry) -> GlobalReadSlotEngine {
        return GlobalReadSlotEngine(
            steps: [
                MinimumGlobalReadSlotAdjuster(minimum: 3.0),
                FlaggedGlobalReadSlotAdjuster(flags: flags, flag: "global-read-slot-weighted", percent: 7.4),
                SegmentGlobalReadSlotAdjuster(factors: ["north": 0.78, "east": 1.23, "online": 1.22]),
                RoundingGlobalReadSlotAdjuster(step: 1.0),
                GlobalReadSlotDiscountOffsetAdjuster(weight: 0.51),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 96651.8
        )
    }
}
