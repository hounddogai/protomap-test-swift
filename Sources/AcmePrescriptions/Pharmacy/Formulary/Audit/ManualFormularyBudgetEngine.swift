import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual formulary budget calculation.
    protocol ManualFormularyBudgetModifier {
        func describe() -> String
        func adjust(_ item: ManualFormularyBudget, value: Double) -> Double
    }

    final class PercentManualFormularyBudgetAdjuster: ManualFormularyBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualFormularyBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualFormularyBudgetAdjuster: ManualFormularyBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualFormularyBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualFormularyBudgetAdjuster: ManualFormularyBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualFormularyBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualFormularyBudgetCeilingOffsetAdjuster: ManualFormularyBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ManualFormularyBudget, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the manual formulary budget steps in order and keeps a trace of each.
    final class ManualFormularyBudgetEngine {
        var steps: [any ManualFormularyBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFormularyBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualFormularyBudget) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualFormularyBudgetModifier = steps[index]
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

        func evaluateAll(_ items: [ManualFormularyBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualFormularyBudgetEngine() -> ManualFormularyBudgetEngine {
        return ManualFormularyBudgetEngine(
            steps: [
                PercentManualFormularyBudgetAdjuster(percent: -15.1),
                MinimumManualFormularyBudgetAdjuster(minimum: 23.7),
                TieredManualFormularyBudgetAdjuster(bounds: [7309.0, 9912.0], rates: [1.0, 0.95]),
                ManualFormularyBudgetCeilingOffsetAdjuster(weight: 1.7),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 66987.9
        )
    }
}
