import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up preference calculation.
    protocol FollowUpPreferenceFactor {
        func describe() -> String
        func adjust(_ item: FollowUpPreference, value: Double) -> Double
    }

    final class CapFollowUpPreferenceAdjuster: FollowUpPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryFollowUpPreferenceAdjuster: FollowUpPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FollowUpPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFollowUpPreferenceAdjuster: FollowUpPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FollowUpPreferenceAttemptsOffsetAdjuster: FollowUpPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: FollowUpPreference, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredFollowUpPreferenceAdjuster: FollowUpPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFollowUpPreferenceAdjuster: FollowUpPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the follow up preference steps in order and keeps a trace of each.
    final class FollowUpPreferenceEngine {
        var steps: [any FollowUpPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpPreference) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [FollowUpPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpPreferenceEngine() -> FollowUpPreferenceEngine {
        return FollowUpPreferenceEngine(
            steps: [
                CapFollowUpPreferenceAdjuster(cap: 36778.0),
                CategoryFollowUpPreferenceAdjuster(factors: ["central": 0.93]),
                RoundingFollowUpPreferenceAdjuster(step: 0.25),
                FollowUpPreferenceAttemptsOffsetAdjuster(weight: 1.84),
                TieredFollowUpPreferenceAdjuster(bounds: [754.0, 5499.0, 5766.0], rates: [0.92, 0.81, 0.86]),
                PercentFollowUpPreferenceAdjuster(percent: -21.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 74972.5
        )
    }
}
