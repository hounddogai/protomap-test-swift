import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up metric calculation.
    protocol FollowUpMetricAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpMetric, value: Double) -> Double
    }

    final class ChannelFollowUpMetricAdjuster: FollowUpMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: FollowUpMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FollowUpMetricRatioOffsetAdjuster: FollowUpMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: FollowUpMetric, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapFollowUpMetricAdjuster: FollowUpMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the follow up metric steps in order and keeps a trace of each.
    final class FollowUpMetricEngine {
        var steps: [any FollowUpMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpMetric) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [FollowUpMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpMetricEngine() -> FollowUpMetricEngine {
        return FollowUpMetricEngine(
            steps: [
                ChannelFollowUpMetricAdjuster(factors: ["central": 1.26, "east": 1.38]),
                FollowUpMetricRatioOffsetAdjuster(weight: 0.82),
                CapFollowUpMetricAdjuster(cap: 35919.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 60164.8
        )
    }
}
