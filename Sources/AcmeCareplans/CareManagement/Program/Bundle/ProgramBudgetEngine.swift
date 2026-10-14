import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program budget calculation.
    protocol ProgramBudgetStep {
        func describe() -> String
        func adjust(_ item: ProgramBudget, value: Double) -> Double
    }

    final class CategoryProgramBudgetAdjuster: ProgramBudgetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ProgramBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumProgramBudgetAdjuster: ProgramBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentProgramBudgetAdjuster: ProgramBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedProgramBudgetAdjuster: ProgramBudgetStep {
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

        func adjust(_ item: ProgramBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ProgramBudgetBatchSizeOffsetAdjuster: ProgramBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ProgramBudget, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the program budget steps in order and keeps a trace of each.
    final class ProgramBudgetEngine {
        var steps: [any ProgramBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProgramBudget) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramBudgetStep = steps[index]
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

        func evaluateAll(_ items: [ProgramBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProgramBudgetEngine(_ flags: Kit.Flags.Registry) -> ProgramBudgetEngine {
        return ProgramBudgetEngine(
            steps: [
                CategoryProgramBudgetAdjuster(factors: ["south": 1.32, "online": 0.97]),
                MinimumProgramBudgetAdjuster(minimum: 36.8),
                PercentProgramBudgetAdjuster(percent: 3.8),
                FlaggedProgramBudgetAdjuster(flags: flags, flag: "program-budget-scheduled", percent: -5.9),
                ProgramBudgetBatchSizeOffsetAdjuster(weight: 0.85),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 98685.3
        )
    }
}
