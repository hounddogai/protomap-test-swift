import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure rule calculation.
    protocol DisclosureRuleFactor {
        func describe() -> String
        func adjust(_ item: DisclosureRule, value: Double) -> Double
    }

    final class DisclosureRuleWindowDaysOffsetAdjuster: DisclosureRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: DisclosureRule, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TieredDisclosureRuleAdjuster: DisclosureRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDisclosureRuleAdjuster: DisclosureRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDisclosureRuleAdjuster: DisclosureRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure rule steps in order and keeps a trace of each.
    final class DisclosureRuleEngine {
        var steps: [any DisclosureRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosureRule) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [DisclosureRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosureRuleEngine() -> DisclosureRuleEngine {
        return DisclosureRuleEngine(
            steps: [
                DisclosureRuleWindowDaysOffsetAdjuster(weight: 1.75),
                TieredDisclosureRuleAdjuster(bounds: [3074.0, 7639.0], rates: [1.19, 0.9]),
                RoundingDisclosureRuleAdjuster(step: 0.25),
                PercentDisclosureRuleAdjuster(percent: 21.4),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 76081.6
        )
    }
}
