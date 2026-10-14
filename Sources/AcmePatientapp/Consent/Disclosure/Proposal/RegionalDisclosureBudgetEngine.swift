import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional disclosure budget calculation.
    protocol RegionalDisclosureBudgetStep {
        func describe() -> String
        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double
    }

    final class CapRegionalDisclosureBudgetAdjuster: RegionalDisclosureBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalDisclosureBudgetAdjuster: RegionalDisclosureBudgetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalDisclosureBudgetAdjuster: RegionalDisclosureBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalDisclosureBudgetAdjuster: RegionalDisclosureBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalDisclosureBudgetCostOffsetAdjuster: RegionalDisclosureBudgetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class MinimumRegionalDisclosureBudgetAdjuster: RegionalDisclosureBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalDisclosureBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional disclosure budget steps in order and keeps a trace of each.
    final class RegionalDisclosureBudgetEngine {
        var steps: [any RegionalDisclosureBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDisclosureBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalDisclosureBudget) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RegionalDisclosureBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalDisclosureBudgetEngine() -> RegionalDisclosureBudgetEngine {
        return RegionalDisclosureBudgetEngine(
            steps: [
                CapRegionalDisclosureBudgetAdjuster(cap: 13204.0),
                TieredRegionalDisclosureBudgetAdjuster(bounds: [6285.0, 7943.0], rates: [0.85, 1.18]),
                PercentRegionalDisclosureBudgetAdjuster(percent: 11.3),
                RoundingRegionalDisclosureBudgetAdjuster(step: 0.1),
                RegionalDisclosureBudgetCostOffsetAdjuster(weight: 1.89),
                MinimumRegionalDisclosureBudgetAdjuster(minimum: 2.6),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 49708.1
        )
    }
}
