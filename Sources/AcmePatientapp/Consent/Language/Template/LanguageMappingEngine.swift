import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language mapping calculation.
    protocol LanguageMappingStep {
        func describe() -> String
        func adjust(_ item: LanguageMapping, value: Double) -> Double
    }

    final class LabelLanguageMappingAdjuster: LanguageMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LanguageMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLanguageMappingAdjuster: LanguageMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLanguageMappingAdjuster: LanguageMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLanguageMappingAdjuster: LanguageMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageMappingDiscountOffsetAdjuster: LanguageMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LanguageMapping, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumLanguageMappingAdjuster: LanguageMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the language mapping steps in order and keeps a trace of each.
    final class LanguageMappingEngine {
        var steps: [any LanguageMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageMapping) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageMappingStep = steps[index]
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

        func evaluateAll(_ items: [LanguageMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageMappingEngine() -> LanguageMappingEngine {
        return LanguageMappingEngine(
            steps: [
                LabelLanguageMappingAdjuster(factors: ["online": 0.83]),
                TieredLanguageMappingAdjuster(
                    bounds: [673.0, 1018.0, 4918.0, 5117.0],
                    rates: [1.14, 1.14, 1.12, 1.11]
                ),
                CapLanguageMappingAdjuster(cap: 27267.0),
                PercentLanguageMappingAdjuster(percent: -15.4),
                LanguageMappingDiscountOffsetAdjuster(weight: 0.67),
                MinimumLanguageMappingAdjuster(minimum: 49.2),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 99057.7
        )
    }
}
