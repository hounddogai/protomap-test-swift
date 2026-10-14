import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction budget calculation.
    protocol InteractionBudgetFactor {
        func describe() -> String
        func adjust(_ item: InteractionBudget, value: Double) -> Double
    }

    final class MinimumInteractionBudgetAdjuster: InteractionBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleInteractionBudgetAdjuster: InteractionBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: InteractionBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingInteractionBudgetAdjuster: InteractionBudgetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedInteractionBudgetAdjuster: InteractionBudgetFactor {
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

        func adjust(_ item: InteractionBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the interaction budget steps in order and keeps a trace of each.
    final class InteractionBudgetEngine {
        var steps: [any InteractionBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionBudget) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [InteractionBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionBudgetEngine(_ flags: Kit.Flags.Registry) -> InteractionBudgetEngine {
        return InteractionBudgetEngine(
            steps: [
                MinimumInteractionBudgetAdjuster(minimum: 43.9),
                LocaleInteractionBudgetAdjuster(factors: ["retail": 1.3, "west": 1.14, "north": 0.94]),
                RoundingInteractionBudgetAdjuster(step: 1.0),
                FlaggedInteractionBudgetAdjuster(flags: flags, flag: "interaction-budget-weighted", percent: 1.9),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 66888.9
        )
    }
}
