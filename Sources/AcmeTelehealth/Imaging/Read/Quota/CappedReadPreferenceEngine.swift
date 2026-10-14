import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped read preference calculation.
    protocol CappedReadPreferenceModifier {
        func describe() -> String
        func adjust(_ item: CappedReadPreference, value: Double) -> Double
    }

    final class TieredCappedReadPreferenceAdjuster: CappedReadPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedReadPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedReadPreferenceUpdatedAtOffsetAdjuster: CappedReadPreferenceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: CappedReadPreference, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentCappedReadPreferenceAdjuster: CappedReadPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedReadPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCappedReadPreferenceAdjuster: CappedReadPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedReadPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedReadPreferenceAdjuster: CappedReadPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedReadPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped read preference steps in order and keeps a trace of each.
    final class CappedReadPreferenceEngine {
        var steps: [any CappedReadPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedReadPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedReadPreference) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [CappedReadPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedReadPreferenceEngine() -> CappedReadPreferenceEngine {
        return CappedReadPreferenceEngine(
            steps: [
                TieredCappedReadPreferenceAdjuster(bounds: [1027.0, 2454.0, 4898.0], rates: [1.05, 0.84, 1.03]),
                CappedReadPreferenceUpdatedAtOffsetAdjuster(weight: 1.34),
                PercentCappedReadPreferenceAdjuster(percent: 23.4),
                TitleCappedReadPreferenceAdjuster(factors: ["central": 1.22, "west": 1.34, "south": 0.89]),
                MinimumCappedReadPreferenceAdjuster(minimum: 43.6),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 69031.2
        )
    }
}
