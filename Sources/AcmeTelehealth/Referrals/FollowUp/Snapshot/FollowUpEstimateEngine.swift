import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up estimate calculation.
    protocol FollowUpEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpEstimate, value: Double) -> Double
    }

    final class FollowUpEstimateExpiresAtOffsetAdjuster: FollowUpEstimateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: FollowUpEstimate, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class PercentFollowUpEstimateAdjuster: FollowUpEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFollowUpEstimateAdjuster: FollowUpEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFollowUpEstimateAdjuster: FollowUpEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFollowUpEstimateAdjuster: FollowUpEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the follow up estimate steps in order and keeps a trace of each.
    final class FollowUpEstimateEngine {
        var steps: [any FollowUpEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FollowUpEstimate) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FollowUpEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFollowUpEstimateEngine() -> FollowUpEstimateEngine {
        return FollowUpEstimateEngine(
            steps: [
                FollowUpEstimateExpiresAtOffsetAdjuster(weight: 0.25),
                PercentFollowUpEstimateAdjuster(percent: -18.8),
                RoundingFollowUpEstimateAdjuster(step: 0.25),
                TieredFollowUpEstimateAdjuster(
                    bounds: [481.0, 2121.0, 3042.0, 9933.0],
                    rates: [1.1, 1.13, 1.01, 0.88]
                ),
                MinimumFollowUpEstimateAdjuster(minimum: 30.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 60722.8
        )
    }
}
