import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix bundle calculation.
    protocol SkillMixBundleAdjuster {
        func describe() -> String
        func adjust(_ item: SkillMixBundle, value: Double) -> Double
    }

    final class PercentSkillMixBundleAdjuster: SkillMixBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleSkillMixBundleAdjuster: SkillMixBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: SkillMixBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSkillMixBundleAdjuster: SkillMixBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSkillMixBundleAdjuster: SkillMixBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the skill mix bundle steps in order and keeps a trace of each.
    final class SkillMixBundleEngine {
        var steps: [any SkillMixBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SkillMixBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [SkillMixBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSkillMixBundleEngine() -> SkillMixBundleEngine {
        return SkillMixBundleEngine(
            steps: [
                PercentSkillMixBundleAdjuster(percent: 24.7),
                LocaleSkillMixBundleAdjuster(factors: ["west": 1.3, "online": 1.02, "central": 1.22]),
                MinimumSkillMixBundleAdjuster(minimum: 46.5),
                TieredSkillMixBundleAdjuster(bounds: [1732.0, 5499.0, 6628.0, 9151.0], rates: [0.83, 0.98, 1.0, 0.86]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 70294.1
        )
    }
}
