import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global acuity plan rule calculation.
    protocol GlobalAcuityPlanRuleAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalAcuityPlanRule, value: Double) -> Double
    }

    final class RoundingGlobalAcuityPlanRuleAdjuster: GlobalAcuityPlanRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalAcuityPlanRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleGlobalAcuityPlanRuleAdjuster: GlobalAcuityPlanRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalAcuityPlanRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalAcuityPlanRuleAdjuster: GlobalAcuityPlanRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAcuityPlanRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global acuity plan rule steps in order and keeps a trace of each.
    final class GlobalAcuityPlanRuleEngine {
        var steps: [any GlobalAcuityPlanRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAcuityPlanRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalAcuityPlanRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAcuityPlanRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalAcuityPlanRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalAcuityPlanRuleEngine() -> GlobalAcuityPlanRuleEngine {
        return GlobalAcuityPlanRuleEngine(
            steps: [
                RoundingGlobalAcuityPlanRuleAdjuster(step: 5.0),
                TitleGlobalAcuityPlanRuleAdjuster(factors: ["east": 1.19, "south": 1.17]),
                MinimumGlobalAcuityPlanRuleAdjuster(minimum: 13.8),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 53217.5
        )
    }
}
