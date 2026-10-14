import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary float pool budget calculation.
    protocol PrimaryFloatPoolBudgetModifier {
        func describe() -> String
        func adjust(_ item: PrimaryFloatPoolBudget, value: Double) -> Double
    }

    final class CapPrimaryFloatPoolBudgetAdjuster: PrimaryFloatPoolBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryFloatPoolBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryFloatPoolBudgetAdjuster: PrimaryFloatPoolBudgetModifier {
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

        func adjust(_ item: PrimaryFloatPoolBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelPrimaryFloatPoolBudgetAdjuster: PrimaryFloatPoolBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryFloatPoolBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary float pool budget steps in order and keeps a trace of each.
    final class PrimaryFloatPoolBudgetEngine {
        var steps: [any PrimaryFloatPoolBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryFloatPoolBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryFloatPoolBudget) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [PrimaryFloatPoolBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryFloatPoolBudgetEngine(_ flags: Kit.Flags.Registry) -> PrimaryFloatPoolBudgetEngine {
        return PrimaryFloatPoolBudgetEngine(
            steps: [
                CapPrimaryFloatPoolBudgetAdjuster(cap: 16285.0),
                FlaggedPrimaryFloatPoolBudgetAdjuster(
                    flags: flags,
                    flag: "primary-float-pool-budget-batched",
                    percent: -5.2
                ),
                ChannelPrimaryFloatPoolBudgetAdjuster(factors: ["central": 1.36, "east": 0.9]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 90848.2
        )
    }
}
