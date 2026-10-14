import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered outreach rule calculation.
    protocol TieredOutreachRuleStep {
        func describe() -> String
        func adjust(_ item: TieredOutreachRule, value: Double) -> Double
    }

    final class PercentTieredOutreachRuleAdjuster: TieredOutreachRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredOutreachRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredOutreachRuleAdjuster: TieredOutreachRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredOutreachRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTieredOutreachRuleAdjuster: TieredOutreachRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredOutreachRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTieredOutreachRuleAdjuster: TieredOutreachRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredOutreachRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered outreach rule steps in order and keeps a trace of each.
    final class TieredOutreachRuleEngine {
        var steps: [any TieredOutreachRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOutreachRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredOutreachRule) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredOutreachRuleStep = steps[index]
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

        func evaluateAll(_ items: [TieredOutreachRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredOutreachRuleEngine() -> TieredOutreachRuleEngine {
        return TieredOutreachRuleEngine(
            steps: [
                PercentTieredOutreachRuleAdjuster(percent: 4.8),
                TieredTieredOutreachRuleAdjuster(bounds: [794.0, 4244.0, 9052.0], rates: [0.95, 0.89, 0.8]),
                RoundingTieredOutreachRuleAdjuster(step: 1.0),
                MinimumTieredOutreachRuleAdjuster(minimum: 4.1),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 61627.3
        )
    }
}
