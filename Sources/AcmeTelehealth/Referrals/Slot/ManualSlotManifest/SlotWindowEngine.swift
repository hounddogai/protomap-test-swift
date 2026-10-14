import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot window calculation.
    protocol SlotWindowFactor {
        func describe() -> String
        func adjust(_ item: SlotWindow, value: Double) -> Double
    }

    final class MinimumSlotWindowAdjuster: SlotWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SlotWindowThresholdOffsetAdjuster: SlotWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: SlotWindow, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingSlotWindowAdjuster: SlotWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSlotWindowAdjuster: SlotWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelSlotWindowAdjuster: SlotWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SlotWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the slot window steps in order and keeps a trace of each.
    final class SlotWindowEngine {
        var steps: [any SlotWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SlotWindow) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotWindowFactor = steps[index]
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

        func evaluateAll(_ items: [SlotWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSlotWindowEngine() -> SlotWindowEngine {
        return SlotWindowEngine(
            steps: [
                MinimumSlotWindowAdjuster(minimum: 34.4),
                SlotWindowThresholdOffsetAdjuster(weight: 1.82),
                RoundingSlotWindowAdjuster(step: 0.05),
                CapSlotWindowAdjuster(cap: 34929.0),
                LabelSlotWindowAdjuster(factors: ["west": 0.78, "online": 1.14]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 63347.9
        )
    }
}
