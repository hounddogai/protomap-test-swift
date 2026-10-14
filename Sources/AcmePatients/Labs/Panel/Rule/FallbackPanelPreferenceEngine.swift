import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback panel preference calculation.
    protocol FallbackPanelPreferenceFactor {
        func describe() -> String
        func adjust(_ item: FallbackPanelPreference, value: Double) -> Double
    }

    final class FacilityFallbackPanelPreferenceAdjuster: FallbackPanelPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackPanelPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFallbackPanelPreferenceAdjuster: FallbackPanelPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackPanelPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackPanelPreferenceMaximumOffsetAdjuster: FallbackPanelPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: FallbackPanelPreference, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the fallback panel preference steps in order and keeps a trace of each.
    final class FallbackPanelPreferenceEngine {
        var steps: [any FallbackPanelPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackPanelPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackPanelPreference) -> Double {
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

        func evaluateAll(_ items: [FallbackPanelPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackPanelPreferenceEngine() -> FallbackPanelPreferenceEngine {
        return FallbackPanelPreferenceEngine(
            steps: [
                FacilityFallbackPanelPreferenceAdjuster(factors: ["central": 0.77, "east": 1.05]),
                PercentFallbackPanelPreferenceAdjuster(percent: -1.7),
                FallbackPanelPreferenceMaximumOffsetAdjuster(weight: 0.5),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 17346.4
        )
    }
}
