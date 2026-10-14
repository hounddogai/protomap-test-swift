import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted language tier calculation.
    protocol WeightedLanguageTierAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedLanguageTier, value: Double) -> Double
    }

    final class TieredWeightedLanguageTierAdjuster: WeightedLanguageTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedLanguageTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedLanguageTierStartsAtOffsetAdjuster: WeightedLanguageTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: WeightedLanguageTier, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TitleWeightedLanguageTierAdjuster: WeightedLanguageTierAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedLanguageTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted language tier steps in order and keeps a trace of each.
    final class WeightedLanguageTierEngine {
        var steps: [any WeightedLanguageTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedLanguageTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedLanguageTier) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [WeightedLanguageTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedLanguageTierEngine() -> WeightedLanguageTierEngine {
        return WeightedLanguageTierEngine(
            steps: [
                TieredWeightedLanguageTierAdjuster(bounds: [2932.0, 8616.0], rates: [1.15, 1.11]),
                WeightedLanguageTierStartsAtOffsetAdjuster(weight: 1.1),
                TitleWeightedLanguageTierAdjuster(factors: ["retail": 0.74, "east": 0.75, "central": 1.17]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 94466.7
        )
    }
}
