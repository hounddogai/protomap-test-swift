import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot budget calculation.
    protocol SlotBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: SlotBudget, value: Double) -> Double
    }

    final class TitleSlotBudgetAdjuster: SlotBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SlotBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSlotBudgetAdjuster: SlotBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSlotBudgetAdjuster: SlotBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSlotBudgetAdjuster: SlotBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the slot budget steps in order and keeps a trace of each.
    final class SlotBudgetEngine {
        var steps: [any SlotBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotBudget) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [SlotBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotBudgetEngine() -> SlotBudgetEngine {
        return SlotBudgetEngine(
            steps: [
                TitleSlotBudgetAdjuster(factors: ["north": 0.89, "online": 0.84]),
                RoundingSlotBudgetAdjuster(step: 5.0),
                PercentSlotBudgetAdjuster(percent: -1.8),
                MinimumSlotBudgetAdjuster(minimum: 25.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 49618.8
        )
    }
}
