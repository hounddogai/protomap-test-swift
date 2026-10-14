import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling denial rule calculation.
    protocol RollingDenialRuleFactor {
        func describe() -> String
        func adjust(_ item: RollingDenialRule, value: Double) -> Double
    }

    final class CapRollingDenialRuleAdjuster: RollingDenialRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingDenialRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryRollingDenialRuleAdjuster: RollingDenialRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RollingDenialRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingDenialRuleVisitMinutesOffsetAdjuster: RollingDenialRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RollingDenialRule, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the rolling denial rule steps in order and keeps a trace of each.
    final class RollingDenialRuleEngine {
        var steps: [any RollingDenialRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDenialRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingDenialRule) -> Double {
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

        func evaluateAll(_ items: [RollingDenialRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingDenialRuleEngine() -> RollingDenialRuleEngine {
        return RollingDenialRuleEngine(
            steps: [
                CapRollingDenialRuleAdjuster(cap: 37602.0),
                CountryRollingDenialRuleAdjuster(factors: ["north": 1.01, "west": 0.86]),
                RollingDenialRuleVisitMinutesOffsetAdjuster(weight: 0.23),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 78983.8
        )
    }
}
