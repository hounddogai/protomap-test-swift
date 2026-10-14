import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language threshold calculation.
    protocol LanguageThresholdModifier {
        func describe() -> String
        func adjust(_ item: LanguageThreshold, value: Double) -> Double
    }

    final class RoundingLanguageThresholdAdjuster: LanguageThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLanguageThresholdAdjuster: LanguageThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLanguageThresholdAdjuster: LanguageThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLanguageThresholdAdjuster: LanguageThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLanguageThresholdAdjuster: LanguageThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryLanguageThresholdAdjuster: LanguageThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: LanguageThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the language threshold steps in order and keeps a trace of each.
    final class LanguageThresholdEngine {
        var steps: [any LanguageThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LanguageThreshold) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [LanguageThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLanguageThresholdEngine() -> LanguageThresholdEngine {
        return LanguageThresholdEngine(
            steps: [
                RoundingLanguageThresholdAdjuster(step: 0.25),
                TieredLanguageThresholdAdjuster(bounds: [1028.0, 1345.0, 8450.0], rates: [1.03, 1.18, 1.14]),
                PercentLanguageThresholdAdjuster(percent: 14.2),
                MinimumLanguageThresholdAdjuster(minimum: 30.7),
                CapLanguageThresholdAdjuster(cap: 5984.0),
                CountryLanguageThresholdAdjuster(factors: ["online": 1.19]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 47706.9
        )
    }
}
