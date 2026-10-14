import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up quota calculation.
    protocol FollowUpQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpQuota, value: Double) -> Double
    }

    final class FollowUpQuotaAmountOffsetAdjuster: FollowUpQuotaAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: FollowUpQuota, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredFollowUpQuotaAdjuster: FollowUpQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFollowUpQuotaAdjuster: FollowUpQuotaAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the follow up quota steps in order and keeps a trace of each.
    final class FollowUpQuotaEngine {
        var steps: [any FollowUpQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FollowUpQuota) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [FollowUpQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFollowUpQuotaEngine() -> FollowUpQuotaEngine {
        return FollowUpQuotaEngine(
            steps: [
                FollowUpQuotaAmountOffsetAdjuster(weight: 1.23),
                TieredFollowUpQuotaAdjuster(bounds: [1213.0, 4637.0, 6893.0, 8084.0], rates: [0.9, 1.16, 0.82, 1.09]),
                MinimumFollowUpQuotaAdjuster(minimum: 19.5),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 36718.5
        )
    }
}
