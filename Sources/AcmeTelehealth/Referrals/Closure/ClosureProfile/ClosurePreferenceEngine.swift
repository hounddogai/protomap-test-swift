import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure preference calculation.
    protocol ClosurePreferenceModifier {
        func describe() -> String
        func adjust(_ item: ClosurePreference, value: Double) -> Double
    }

    final class PercentClosurePreferenceAdjuster: ClosurePreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosurePreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClosurePreferenceAdjuster: ClosurePreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosurePreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ClosurePreferenceScoreOffsetAdjuster: ClosurePreferenceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ClosurePreference, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RegionClosurePreferenceAdjuster: ClosurePreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ClosurePreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the closure preference steps in order and keeps a trace of each.
    final class ClosurePreferenceEngine {
        var steps: [any ClosurePreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosurePreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosurePreference) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ClosurePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosurePreferenceEngine() -> ClosurePreferenceEngine {
        return ClosurePreferenceEngine(
            steps: [
                PercentClosurePreferenceAdjuster(percent: -5.2),
                TieredClosurePreferenceAdjuster(
                    bounds: [1740.0, 4246.0, 5927.0, 9692.0],
                    rates: [1.07, 1.2, 1.03, 0.96]
                ),
                ClosurePreferenceScoreOffsetAdjuster(weight: 1.01),
                RegionClosurePreferenceAdjuster(factors: ["north": 1.14, "south": 1.14, "central": 1.12]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 54745.6
        )
    }
}
