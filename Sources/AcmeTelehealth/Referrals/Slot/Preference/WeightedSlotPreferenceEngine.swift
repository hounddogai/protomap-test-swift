import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted slot preference calculation.
    protocol WeightedSlotPreferenceStep {
        func describe() -> String
        func adjust(_ item: WeightedSlotPreference, value: Double) -> Double
    }

    final class WeightedSlotPreferenceScoreOffsetAdjuster: WeightedSlotPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: WeightedSlotPreference, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredWeightedSlotPreferenceAdjuster: WeightedSlotPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSlotPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedSlotPreferenceAdjuster: WeightedSlotPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSlotPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleWeightedSlotPreferenceAdjuster: WeightedSlotPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: WeightedSlotPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedSlotPreferenceAdjuster: WeightedSlotPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSlotPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted slot preference steps in order and keeps a trace of each.
    final class WeightedSlotPreferenceEngine {
        var steps: [any WeightedSlotPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSlotPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedSlotPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSlotPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [WeightedSlotPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedSlotPreferenceEngine() -> WeightedSlotPreferenceEngine {
        return WeightedSlotPreferenceEngine(
            steps: [
                WeightedSlotPreferenceScoreOffsetAdjuster(weight: 1.12),
                TieredWeightedSlotPreferenceAdjuster(bounds: [5683.0, 7367.0], rates: [0.8, 0.93]),
                PercentWeightedSlotPreferenceAdjuster(percent: 24.5),
                LocaleWeightedSlotPreferenceAdjuster(factors: ["north": 1.28, "south": 1.3, "online": 0.95]),
                CapWeightedSlotPreferenceAdjuster(cap: 13627.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 58841.0
        )
    }
}
