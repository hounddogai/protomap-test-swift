import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary slot budget calculation.
    protocol PrimarySlotBudgetStep {
        func describe() -> String
        func adjust(_ item: PrimarySlotBudget, value: Double) -> Double
    }

    final class RoundingPrimarySlotBudgetAdjuster: PrimarySlotBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySlotBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PrimarySlotBudgetUpdatedAtOffsetAdjuster: PrimarySlotBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: PrimarySlotBudget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class MinimumPrimarySlotBudgetAdjuster: PrimarySlotBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimarySlotBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary slot budget steps in order and keeps a trace of each.
    final class PrimarySlotBudgetEngine {
        var steps: [any PrimarySlotBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySlotBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimarySlotBudget) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySlotBudgetStep = steps[index]
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

        func evaluateAll(_ items: [PrimarySlotBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimarySlotBudgetEngine() -> PrimarySlotBudgetEngine {
        return PrimarySlotBudgetEngine(
            steps: [
                RoundingPrimarySlotBudgetAdjuster(step: 1.0),
                PrimarySlotBudgetUpdatedAtOffsetAdjuster(weight: 1.4),
                MinimumPrimarySlotBudgetAdjuster(minimum: 32.8),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 15185.1
        )
    }
}
