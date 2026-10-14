import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual priority budget calculation.
    protocol ManualPriorityBudgetFactor {
        func describe() -> String
        func adjust(_ item: ManualPriorityBudget, value: Double) -> Double
    }

    final class TieredManualPriorityBudgetAdjuster: ManualPriorityBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualPriorityBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualPriorityBudgetRevisionOffsetAdjuster: ManualPriorityBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ManualPriorityBudget, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedManualPriorityBudgetAdjuster: ManualPriorityBudgetFactor {
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

        func adjust(_ item: ManualPriorityBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualPriorityBudgetAdjuster: ManualPriorityBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualPriorityBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual priority budget steps in order and keeps a trace of each.
    final class ManualPriorityBudgetEngine {
        var steps: [any ManualPriorityBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualPriorityBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualPriorityBudget) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualPriorityBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [ManualPriorityBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualPriorityBudgetEngine(_ flags: Kit.Flags.Registry) -> ManualPriorityBudgetEngine {
        return ManualPriorityBudgetEngine(
            steps: [
                TieredManualPriorityBudgetAdjuster(bounds: [379.0, 9638.0], rates: [0.8, 1.08]),
                ManualPriorityBudgetRevisionOffsetAdjuster(weight: 0.62),
                FlaggedManualPriorityBudgetAdjuster(
                    flags: flags,
                    flag: "manual-priority-budget-manual",
                    percent: -6.8
                ),
                PercentManualPriorityBudgetAdjuster(percent: -14.6),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 21792.2
        )
    }
}
