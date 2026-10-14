import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy proxy budget calculation.
    protocol LegacyProxyBudgetModifier {
        func describe() -> String
        func adjust(_ item: LegacyProxyBudget, value: Double) -> Double
    }

    final class TieredLegacyProxyBudgetAdjuster: LegacyProxyBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyProxyBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyProxyBudgetAdjuster: LegacyProxyBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyProxyBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyProxyBudgetAdjuster: LegacyProxyBudgetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyProxyBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy proxy budget steps in order and keeps a trace of each.
    final class LegacyProxyBudgetEngine {
        var steps: [any LegacyProxyBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyProxyBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyProxyBudget) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [LegacyProxyBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyProxyBudgetEngine() -> LegacyProxyBudgetEngine {
        return LegacyProxyBudgetEngine(
            steps: [
                TieredLegacyProxyBudgetAdjuster(bounds: [2456.0, 9949.0], rates: [1.16, 1.05]),
                MinimumLegacyProxyBudgetAdjuster(minimum: 45.3),
                RoundingLegacyProxyBudgetAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 35132.4
        )
    }
}
