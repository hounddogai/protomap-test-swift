import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive accession budget calculation.
    protocol AdaptiveAccessionBudgetModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveAccessionBudget, value: Double) -> Double
    }

    final class CapAdaptiveAccessionBudgetAdjuster: AdaptiveAccessionBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveAccessionBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryAdaptiveAccessionBudgetAdjuster: AdaptiveAccessionBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AdaptiveAccessionBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAdaptiveAccessionBudgetAdjuster: AdaptiveAccessionBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveAccessionBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive accession budget steps in order and keeps a trace of each.
    final class AdaptiveAccessionBudgetEngine {
        var steps: [any AdaptiveAccessionBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAccessionBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveAccessionBudget) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveAccessionBudgetModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveAccessionBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAccessionBudgetEngine() -> AdaptiveAccessionBudgetEngine {
        return AdaptiveAccessionBudgetEngine(
            steps: [
                CapAdaptiveAccessionBudgetAdjuster(cap: 23250.0),
                CountryAdaptiveAccessionBudgetAdjuster(factors: ["south": 1.18, "retail": 0.87]),
                MinimumAdaptiveAccessionBudgetAdjuster(minimum: 49.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 22726.9
        )
    }
}
