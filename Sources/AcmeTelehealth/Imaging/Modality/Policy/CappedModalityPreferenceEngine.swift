import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality preference calculation.
    protocol CappedModalityPreferenceModifier {
        func describe() -> String
        func adjust(_ item: CappedModalityPreference, value: Double) -> Double
    }

    final class UnitCappedModalityPreferenceAdjuster: CappedModalityPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedModalityPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedModalityPreferenceAdjuster: CappedModalityPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedModalityPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedModalityPreferenceRetriesOffsetAdjuster: CappedModalityPreferenceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: CappedModalityPreference, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the capped modality preference steps in order and keeps a trace of each.
    final class CappedModalityPreferenceEngine {
        var steps: [any CappedModalityPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedModalityPreference) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [CappedModalityPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedModalityPreferenceEngine() -> CappedModalityPreferenceEngine {
        return CappedModalityPreferenceEngine(
            steps: [
                UnitCappedModalityPreferenceAdjuster(factors: ["online": 0.79]),
                TieredCappedModalityPreferenceAdjuster(
                    bounds: [15.0, 1195.0, 2364.0, 7142.0],
                    rates: [1.05, 0.89, 0.85, 0.8]
                ),
                CappedModalityPreferenceRetriesOffsetAdjuster(weight: 1.8),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 96858.9
        )
    }
}
