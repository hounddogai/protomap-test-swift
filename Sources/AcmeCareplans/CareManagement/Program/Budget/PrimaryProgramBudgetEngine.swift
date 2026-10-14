import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary program budget calculation.
    protocol PrimaryProgramBudgetModifier {
        func describe() -> String
        func adjust(_ item: PrimaryProgramBudget, value: Double) -> Double
    }

    final class CapPrimaryProgramBudgetAdjuster: PrimaryProgramBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryProgramBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryProgramBudgetAdjuster: PrimaryProgramBudgetModifier {
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

        func adjust(_ item: PrimaryProgramBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryProgramBudgetAdjuster: PrimaryProgramBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryProgramBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryProgramBudgetAdjuster: PrimaryProgramBudgetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryProgramBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelPrimaryProgramBudgetAdjuster: PrimaryProgramBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryProgramBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary program budget steps in order and keeps a trace of each.
    final class PrimaryProgramBudgetEngine {
        var steps: [any PrimaryProgramBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryProgramBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryProgramBudget) -> Double {
            var current = item.projectedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PrimaryProgramBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryProgramBudgetEngine(_ flags: Kit.Flags.Registry) -> PrimaryProgramBudgetEngine {
        return PrimaryProgramBudgetEngine(
            steps: [
                CapPrimaryProgramBudgetAdjuster(cap: 45192.0),
                FlaggedPrimaryProgramBudgetAdjuster(
                    flags: flags,
                    flag: "primary-program-budget-seasonal",
                    percent: 8.4
                ),
                PercentPrimaryProgramBudgetAdjuster(percent: -9.1),
                RoundingPrimaryProgramBudgetAdjuster(step: 5.0),
                LabelPrimaryProgramBudgetAdjuster(factors: ["north": 1.33, "east": 1.01, "west": 0.74]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 84070.2
        )
    }
}
