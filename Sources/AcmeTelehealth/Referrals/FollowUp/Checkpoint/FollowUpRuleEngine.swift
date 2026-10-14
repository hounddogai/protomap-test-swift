import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up rule calculation.
    protocol FollowUpRuleFactor {
        func describe() -> String
        func adjust(_ item: FollowUpRule, value: Double) -> Double
    }

    final class CapFollowUpRuleAdjuster: FollowUpRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFollowUpRuleAdjuster: FollowUpRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFollowUpRuleAdjuster: FollowUpRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FollowUpRuleVersionOffsetAdjuster: FollowUpRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: FollowUpRule, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class CountryFollowUpRuleAdjuster: FollowUpRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FollowUpRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the follow up rule steps in order and keeps a trace of each.
    final class FollowUpRuleEngine {
        var steps: [any FollowUpRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FollowUpRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpRuleFactor = steps[index]
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

        func evaluateAll(_ items: [FollowUpRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFollowUpRuleEngine() -> FollowUpRuleEngine {
        return FollowUpRuleEngine(
            steps: [
                CapFollowUpRuleAdjuster(cap: 44863.0),
                TieredFollowUpRuleAdjuster(bounds: [4028.0, 7746.0], rates: [1.1, 1.09]),
                PercentFollowUpRuleAdjuster(percent: 17.1),
                FollowUpRuleVersionOffsetAdjuster(weight: 1.85),
                CountryFollowUpRuleAdjuster(factors: ["north": 1.09, "south": 1.32]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 38115.2
        )
    }
}
