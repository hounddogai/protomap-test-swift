import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted language request calculation.
    protocol WeightedLanguageRequestStep {
        func describe() -> String
        func adjust(_ item: WeightedLanguageRequest, value: Double) -> Double
    }

    final class RoundingWeightedLanguageRequestAdjuster: WeightedLanguageRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedLanguageRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedLanguageRequestAdjuster: WeightedLanguageRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedLanguageRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedLanguageRequestAdjuster: WeightedLanguageRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedLanguageRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedLanguageRequestDiscountOffsetAdjuster: WeightedLanguageRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: WeightedLanguageRequest, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentWeightedLanguageRequestAdjuster: WeightedLanguageRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedLanguageRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted language request steps in order and keeps a trace of each.
    final class WeightedLanguageRequestEngine {
        var steps: [any WeightedLanguageRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedLanguageRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedLanguageRequest) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [WeightedLanguageRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedLanguageRequestEngine() -> WeightedLanguageRequestEngine {
        return WeightedLanguageRequestEngine(
            steps: [
                RoundingWeightedLanguageRequestAdjuster(step: 0.1),
                CapWeightedLanguageRequestAdjuster(cap: 7387.0),
                MinimumWeightedLanguageRequestAdjuster(minimum: 14.9),
                WeightedLanguageRequestDiscountOffsetAdjuster(weight: 1.48),
                PercentWeightedLanguageRequestAdjuster(percent: 7.7),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 92609.0
        )
    }
}
