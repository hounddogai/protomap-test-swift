import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending skill mix preference calculation.
    protocol PendingSkillMixPreferenceFactor {
        func describe() -> String
        func adjust(_ item: PendingSkillMixPreference, value: Double) -> Double
    }

    final class FacilityPendingSkillMixPreferenceAdjuster: PendingSkillMixPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PendingSkillMixPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingSkillMixPreferenceAdjuster: PendingSkillMixPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingSkillMixPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPendingSkillMixPreferenceAdjuster: PendingSkillMixPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingSkillMixPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending skill mix preference steps in order and keeps a trace of each.
    final class PendingSkillMixPreferenceEngine {
        var steps: [any PendingSkillMixPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSkillMixPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingSkillMixPreference) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingSkillMixPreferenceFactor = steps[index]
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

        func evaluateAll(_ items: [PendingSkillMixPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingSkillMixPreferenceEngine() -> PendingSkillMixPreferenceEngine {
        return PendingSkillMixPreferenceEngine(
            steps: [
                FacilityPendingSkillMixPreferenceAdjuster(factors: ["north": 0.71]),
                TieredPendingSkillMixPreferenceAdjuster(
                    bounds: [3767.0, 5053.0, 8688.0, 8902.0],
                    rates: [1.07, 0.87, 1.05, 0.98]
                ),
                MinimumPendingSkillMixPreferenceAdjuster(minimum: 3.9),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 35222.0
        )
    }
}
