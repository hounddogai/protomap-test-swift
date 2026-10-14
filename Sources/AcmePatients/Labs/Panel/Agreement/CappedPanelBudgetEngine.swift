import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped panel budget calculation.
    protocol CappedPanelBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: CappedPanelBudget, value: Double) -> Double
    }

    final class FlaggedCappedPanelBudgetAdjuster: CappedPanelBudgetAdjuster {
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

        func adjust(_ item: CappedPanelBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedPanelBudgetAdjuster: CappedPanelBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedPanelBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CappedPanelBudgetLimitOffsetAdjuster: CappedPanelBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: CappedPanelBudget, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the capped panel budget steps in order and keeps a trace of each.
    final class CappedPanelBudgetEngine {
        var steps: [any CappedPanelBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedPanelBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedPanelBudget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CappedPanelBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedPanelBudgetEngine(_ flags: Kit.Flags.Registry) -> CappedPanelBudgetEngine {
        return CappedPanelBudgetEngine(
            steps: [
                FlaggedCappedPanelBudgetAdjuster(flags: flags, flag: "capped-panel-budget-regional", percent: -4.9),
                RoundingCappedPanelBudgetAdjuster(step: 0.25),
                CappedPanelBudgetLimitOffsetAdjuster(weight: 1.41),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 2557.1
        )
    }
}
