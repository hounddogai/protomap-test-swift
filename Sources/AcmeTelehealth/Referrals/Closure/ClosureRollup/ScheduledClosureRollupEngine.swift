import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled closure rollup calculation.
    protocol ScheduledClosureRollupFactor {
        func describe() -> String
        func adjust(_ item: ScheduledClosureRollup, value: Double) -> Double
    }

    final class ChannelScheduledClosureRollupAdjuster: ScheduledClosureRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ScheduledClosureRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledClosureRollupAdjuster: ScheduledClosureRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledClosureRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledClosureRollupAdjuster: ScheduledClosureRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledClosureRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ScheduledClosureRollupWeightOffsetAdjuster: ScheduledClosureRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ScheduledClosureRollup, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the scheduled closure rollup steps in order and keeps a trace of each.
    final class ScheduledClosureRollupEngine {
        var steps: [any ScheduledClosureRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledClosureRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledClosureRollup) -> Double {
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

        func evaluateAll(_ items: [ScheduledClosureRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledClosureRollupEngine() -> ScheduledClosureRollupEngine {
        return ScheduledClosureRollupEngine(
            steps: [
                ChannelScheduledClosureRollupAdjuster(factors: ["retail": 1.13, "east": 1.28]),
                PercentScheduledClosureRollupAdjuster(percent: 3.4),
                RoundingScheduledClosureRollupAdjuster(step: 0.05),
                ScheduledClosureRollupWeightOffsetAdjuster(weight: 1.42),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 47655.9
        )
    }
}
