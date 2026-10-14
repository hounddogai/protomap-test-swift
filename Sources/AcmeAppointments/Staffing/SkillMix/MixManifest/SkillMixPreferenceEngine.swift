import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix preference calculation.
    protocol SkillMixPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixPreference, value: Double) -> Double
    }

    final class MinimumSkillMixPreferenceAdjuster: SkillMixPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSkillMixPreferenceAdjuster: SkillMixPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSkillMixPreferenceAdjuster: SkillMixPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSkillMixPreferenceAdjuster: SkillMixPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the skill mix preference steps in order and keeps a trace of each.
    final class SkillMixPreferenceEngine {
        var steps: [any SkillMixPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SkillMixPreference) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [SkillMixPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSkillMixPreferenceEngine() -> SkillMixPreferenceEngine {
        return SkillMixPreferenceEngine(
            steps: [
                MinimumSkillMixPreferenceAdjuster(minimum: 23.1),
                TieredSkillMixPreferenceAdjuster(bounds: [3834.0, 4638.0, 9981.0], rates: [0.98, 0.92, 0.99]),
                CapSkillMixPreferenceAdjuster(cap: 45183.0),
                PercentSkillMixPreferenceAdjuster(percent: -15.6),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 12839.1
        )
    }
}
