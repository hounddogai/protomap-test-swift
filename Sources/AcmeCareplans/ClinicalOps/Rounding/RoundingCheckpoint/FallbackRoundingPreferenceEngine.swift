import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback rounding preference calculation.
    protocol FallbackRoundingPreferenceStep {
        func describe() -> String
        func adjust(_ item: FallbackRoundingPreference, value: Double) -> Double
    }

    final class PercentFallbackRoundingPreferenceAdjuster: FallbackRoundingPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackRoundingPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackRoundingPreferenceLimitOffsetAdjuster: FallbackRoundingPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: FallbackRoundingPreference, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class SourceFallbackRoundingPreferenceAdjuster: FallbackRoundingPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FallbackRoundingPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback rounding preference steps in order and keeps a trace of each.
    final class FallbackRoundingPreferenceEngine {
        var steps: [any FallbackRoundingPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRoundingPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackRoundingPreference) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FallbackRoundingPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackRoundingPreferenceEngine() -> FallbackRoundingPreferenceEngine {
        return FallbackRoundingPreferenceEngine(
            steps: [
                PercentFallbackRoundingPreferenceAdjuster(percent: 15.6),
                FallbackRoundingPreferenceLimitOffsetAdjuster(weight: 1.34),
                SourceFallbackRoundingPreferenceAdjuster(factors: ["south": 0.83]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 27709.6
        )
    }
}
