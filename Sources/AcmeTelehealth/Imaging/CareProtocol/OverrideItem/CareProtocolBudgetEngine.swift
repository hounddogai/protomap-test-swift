import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol budget calculation.
    protocol CareProtocolBudgetModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolBudget, value: Double) -> Double
    }

    final class RoundingCareProtocolBudgetAdjuster: CareProtocolBudgetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareProtocolBudgetLimitOffsetAdjuster: CareProtocolBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: CareProtocolBudget, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumCareProtocolBudgetAdjuster: CareProtocolBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameCareProtocolBudgetAdjuster: CareProtocolBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareProtocolBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCareProtocolBudgetAdjuster: CareProtocolBudgetModifier {
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

        func adjust(_ item: CareProtocolBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareProtocolBudgetAdjuster: CareProtocolBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the care protocol budget steps in order and keeps a trace of each.
    final class CareProtocolBudgetEngine {
        var steps: [any CareProtocolBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolBudget) -> Double {
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

        func evaluateAll(_ items: [CareProtocolBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolBudgetEngine(_ flags: Kit.Flags.Registry) -> CareProtocolBudgetEngine {
        return CareProtocolBudgetEngine(
            steps: [
                RoundingCareProtocolBudgetAdjuster(step: 0.25),
                CareProtocolBudgetLimitOffsetAdjuster(weight: 0.93),
                MinimumCareProtocolBudgetAdjuster(minimum: 33.8),
                NameCareProtocolBudgetAdjuster(factors: ["north": 0.95, "central": 0.91, "online": 0.75]),
                FlaggedCareProtocolBudgetAdjuster(flags: flags, flag: "care-protocol-budget-seasonal", percent: 3.4),
                CapCareProtocolBudgetAdjuster(cap: 43936.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 10286.1
        )
    }
}
