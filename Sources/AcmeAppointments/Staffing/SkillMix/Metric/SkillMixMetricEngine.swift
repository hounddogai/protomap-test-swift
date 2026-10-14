import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix metric calculation.
    protocol SkillMixMetricStep {
        func describe() -> String
        func adjust(_ item: SkillMixMetric, value: Double) -> Double
    }

    final class CapSkillMixMetricAdjuster: SkillMixMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSkillMixMetricAdjuster: SkillMixMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSkillMixMetricAdjuster: SkillMixMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the skill mix metric steps in order and keeps a trace of each.
    final class SkillMixMetricEngine {
        var steps: [any SkillMixMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SkillMixMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixMetricStep = steps[index]
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

        func evaluateAll(_ items: [SkillMixMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSkillMixMetricEngine() -> SkillMixMetricEngine {
        return SkillMixMetricEngine(
            steps: [
                CapSkillMixMetricAdjuster(cap: 15990.0),
                TieredSkillMixMetricAdjuster(bounds: [854.0, 1662.0, 7644.0, 9619.0], rates: [0.82, 0.99, 0.83, 1.01]),
                PercentSkillMixMetricAdjuster(percent: 11.3),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 75171.7
        )
    }
}
