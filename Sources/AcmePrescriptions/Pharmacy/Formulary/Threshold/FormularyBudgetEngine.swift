import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary budget calculation.
    protocol FormularyBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: FormularyBudget, value: Double) -> Double
    }

    final class MinimumFormularyBudgetAdjuster: FormularyBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFormularyBudgetAdjuster: FormularyBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFormularyBudgetAdjuster: FormularyBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFormularyBudgetAdjuster: FormularyBudgetAdjuster {
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

        func adjust(_ item: FormularyBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFormularyBudgetAdjuster: FormularyBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FormularyBudgetLimitOffsetAdjuster: FormularyBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: FormularyBudget, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the formulary budget steps in order and keeps a trace of each.
    final class FormularyBudgetEngine {
        var steps: [any FormularyBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyBudget) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [FormularyBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyBudgetEngine(_ flags: Kit.Flags.Registry) -> FormularyBudgetEngine {
        return FormularyBudgetEngine(
            steps: [
                MinimumFormularyBudgetAdjuster(minimum: 9.9),
                PercentFormularyBudgetAdjuster(percent: -13.4),
                CapFormularyBudgetAdjuster(cap: 26331.0),
                FlaggedFormularyBudgetAdjuster(flags: flags, flag: "formulary-budget-lenient", percent: 1.1),
                TieredFormularyBudgetAdjuster(bounds: [862.0, 7132.0], rates: [1.03, 1.17]),
                FormularyBudgetLimitOffsetAdjuster(weight: 1.94),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 5640.5
        )
    }
}
