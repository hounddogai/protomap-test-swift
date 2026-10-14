import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive goal preference calculation.
    protocol AdaptiveGoalPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveGoalPreference, value: Double) -> Double
    }

    final class AdaptiveGoalPreferenceLimitOffsetAdjuster: AdaptiveGoalPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: AdaptiveGoalPreference, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class TieredAdaptiveGoalPreferenceAdjuster: AdaptiveGoalPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveGoalPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveGoalPreferenceAdjuster: AdaptiveGoalPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveGoalPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceAdaptiveGoalPreferenceAdjuster: AdaptiveGoalPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AdaptiveGoalPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAdaptiveGoalPreferenceAdjuster: AdaptiveGoalPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveGoalPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive goal preference steps in order and keeps a trace of each.
    final class AdaptiveGoalPreferenceEngine {
        var steps: [any AdaptiveGoalPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveGoalPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveGoalPreference) -> Double {
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

        func evaluateAll(_ items: [AdaptiveGoalPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveGoalPreferenceEngine() -> AdaptiveGoalPreferenceEngine {
        return AdaptiveGoalPreferenceEngine(
            steps: [
                AdaptiveGoalPreferenceLimitOffsetAdjuster(weight: 0.37),
                TieredAdaptiveGoalPreferenceAdjuster(
                    bounds: [1450.0, 7165.0, 8786.0, 8818.0],
                    rates: [1.2, 0.95, 1.12, 1.08]
                ),
                MinimumAdaptiveGoalPreferenceAdjuster(minimum: 38.5),
                SourceAdaptiveGoalPreferenceAdjuster(factors: ["online": 0.8]),
                PercentAdaptiveGoalPreferenceAdjuster(percent: 3.7),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 83176.3
        )
    }
}
