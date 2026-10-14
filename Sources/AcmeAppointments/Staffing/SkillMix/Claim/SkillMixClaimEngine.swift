import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix claim calculation.
    protocol SkillMixClaimModifier {
        func describe() -> String
        func adjust(_ item: SkillMixClaim, value: Double) -> Double
    }

    final class TieredSkillMixClaimAdjuster: SkillMixClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSkillMixClaimAdjuster: SkillMixClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSkillMixClaimAdjuster: SkillMixClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSkillMixClaimAdjuster: SkillMixClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionSkillMixClaimAdjuster: SkillMixClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SkillMixClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the skill mix claim steps in order and keeps a trace of each.
    final class SkillMixClaimEngine {
        var steps: [any SkillMixClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixClaimModifier = steps[index]
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

        func evaluateAll(_ items: [SkillMixClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixClaimEngine() -> SkillMixClaimEngine {
        return SkillMixClaimEngine(
            steps: [
                TieredSkillMixClaimAdjuster(bounds: [1744.0, 7563.0, 9761.0], rates: [0.99, 1.11, 0.91]),
                MinimumSkillMixClaimAdjuster(minimum: 25.9),
                PercentSkillMixClaimAdjuster(percent: 6.2),
                RoundingSkillMixClaimAdjuster(step: 0.5),
                RegionSkillMixClaimAdjuster(factors: ["online": 0.77]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 26810.6
        )
    }
}
