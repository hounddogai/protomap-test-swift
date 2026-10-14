import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy recall slot calculation.
    protocol LegacyRecallSlotModifier {
        func describe() -> String
        func adjust(_ item: LegacyRecallSlot, value: Double) -> Double
    }

    final class RoundingLegacyRecallSlotAdjuster: LegacyRecallSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyRecallSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentLegacyRecallSlotAdjuster: LegacyRecallSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: LegacyRecallSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacyRecallSlotBudgetOffsetAdjuster: LegacyRecallSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: LegacyRecallSlot, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the legacy recall slot steps in order and keeps a trace of each.
    final class LegacyRecallSlotEngine {
        var steps: [any LegacyRecallSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRecallSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyRecallSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyRecallSlotModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyRecallSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyRecallSlotEngine() -> LegacyRecallSlotEngine {
        return LegacyRecallSlotEngine(
            steps: [
                RoundingLegacyRecallSlotAdjuster(step: 1.0),
                SegmentLegacyRecallSlotAdjuster(factors: ["west": 0.82]),
                LegacyRecallSlotBudgetOffsetAdjuster(weight: 0.76),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 63806.7
        )
    }
}
