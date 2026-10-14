import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary language budget calculation.
    protocol PrimaryLanguageBudgetStep {
        func describe() -> String
        func adjust(_ item: PrimaryLanguageBudget, value: Double) -> Double
    }

    final class CapPrimaryLanguageBudgetAdjuster: PrimaryLanguageBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryLanguageBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryLanguageBudgetAdjuster: PrimaryLanguageBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryLanguageBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryLanguageBudgetAdjuster: PrimaryLanguageBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryLanguageBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryLanguageBudgetAdjuster: PrimaryLanguageBudgetStep {
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

        func adjust(_ item: PrimaryLanguageBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryLanguageBudgetRateOffsetAdjuster: PrimaryLanguageBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: PrimaryLanguageBudget, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the primary language budget steps in order and keeps a trace of each.
    final class PrimaryLanguageBudgetEngine {
        var steps: [any PrimaryLanguageBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryLanguageBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryLanguageBudget) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [PrimaryLanguageBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryLanguageBudgetEngine(_ flags: Kit.Flags.Registry) -> PrimaryLanguageBudgetEngine {
        return PrimaryLanguageBudgetEngine(
            steps: [
                CapPrimaryLanguageBudgetAdjuster(cap: 36166.0),
                RoundingPrimaryLanguageBudgetAdjuster(step: 1.0),
                PercentPrimaryLanguageBudgetAdjuster(percent: -12.0),
                FlaggedPrimaryLanguageBudgetAdjuster(
                    flags: flags,
                    flag: "primary-language-budget-seasonal",
                    percent: -4.4
                ),
                PrimaryLanguageBudgetRateOffsetAdjuster(weight: 1.99),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 53260.6
        )
    }
}
