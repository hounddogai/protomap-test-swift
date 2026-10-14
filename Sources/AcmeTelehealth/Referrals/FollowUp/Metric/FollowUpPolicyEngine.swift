import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up policy calculation.
    protocol FollowUpPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpPolicy, value: Double) -> Double
    }

    final class TieredFollowUpPolicyAdjuster: FollowUpPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FollowUpPolicyRevisionOffsetAdjuster: FollowUpPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: FollowUpPolicy, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class MinimumFollowUpPolicyAdjuster: FollowUpPolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the follow up policy steps in order and keeps a trace of each.
    final class FollowUpPolicyEngine {
        var steps: [any FollowUpPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FollowUpPolicy) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [FollowUpPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFollowUpPolicyEngine() -> FollowUpPolicyEngine {
        return FollowUpPolicyEngine(
            steps: [
                TieredFollowUpPolicyAdjuster(bounds: [1561.0, 5222.0, 9248.0], rates: [0.98, 1.1, 1.16]),
                FollowUpPolicyRevisionOffsetAdjuster(weight: 1.12),
                MinimumFollowUpPolicyAdjuster(minimum: 48.2),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 11901.6
        )
    }
}
