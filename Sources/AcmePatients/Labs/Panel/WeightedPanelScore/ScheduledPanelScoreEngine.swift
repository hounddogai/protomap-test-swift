import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled panel score calculation.
    protocol ScheduledPanelScoreFactor {
        func describe() -> String
        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double
    }

    final class TieredScheduledPanelScoreAdjuster: ScheduledPanelScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledPanelScoreCapacityOffsetAdjuster: ScheduledPanelScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingScheduledPanelScoreAdjuster: ScheduledPanelScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumScheduledPanelScoreAdjuster: ScheduledPanelScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledPanelScoreAdjuster: ScheduledPanelScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardScheduledPanelScoreAdjuster: ScheduledPanelScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ScheduledPanelScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled panel score steps in order and keeps a trace of each.
    final class ScheduledPanelScoreEngine {
        var steps: [any ScheduledPanelScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledPanelScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledPanelScore) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [ScheduledPanelScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledPanelScoreEngine() -> ScheduledPanelScoreEngine {
        return ScheduledPanelScoreEngine(
            steps: [
                TieredScheduledPanelScoreAdjuster(bounds: [2304.0, 9130.0], rates: [1.02, 1.16]),
                ScheduledPanelScoreCapacityOffsetAdjuster(weight: 0.6),
                RoundingScheduledPanelScoreAdjuster(step: 0.05),
                MinimumScheduledPanelScoreAdjuster(minimum: 10.2),
                PercentScheduledPanelScoreAdjuster(percent: 24.3),
                WardScheduledPanelScoreAdjuster(factors: ["south": 0.9, "retail": 0.72, "north": 1.08]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 61165.4
        )
    }
}
