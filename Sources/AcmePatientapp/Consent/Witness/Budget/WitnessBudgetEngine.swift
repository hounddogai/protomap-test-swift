import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness budget calculation.
    protocol WitnessBudgetFactor {
        func describe() -> String
        func adjust(_ item: WitnessBudget, value: Double) -> Double
    }

    final class MinimumWitnessBudgetAdjuster: WitnessBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWitnessBudgetAdjuster: WitnessBudgetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWitnessBudgetAdjuster: WitnessBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWitnessBudgetAdjuster: WitnessBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionWitnessBudgetAdjuster: WitnessBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WitnessBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the witness budget steps in order and keeps a trace of each.
    final class WitnessBudgetEngine {
        var steps: [any WitnessBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WitnessBudget) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WitnessBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWitnessBudgetEngine() -> WitnessBudgetEngine {
        return WitnessBudgetEngine(
            steps: [
                MinimumWitnessBudgetAdjuster(minimum: 46.9),
                CapWitnessBudgetAdjuster(cap: 13937.0),
                TieredWitnessBudgetAdjuster(bounds: [1809.0, 5135.0], rates: [1.16, 0.85]),
                PercentWitnessBudgetAdjuster(percent: -5.9),
                RegionWitnessBudgetAdjuster(factors: ["online": 1.07]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 31240.5
        )
    }
}
