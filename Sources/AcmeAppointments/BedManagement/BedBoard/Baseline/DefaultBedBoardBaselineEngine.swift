import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default bed board baseline calculation.
    protocol DefaultBedBoardBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double
    }

    final class MinimumDefaultBedBoardBaselineAdjuster: DefaultBedBoardBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultBedBoardBaselineGraceDaysOffsetAdjuster: DefaultBedBoardBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredDefaultBedBoardBaselineAdjuster: DefaultBedBoardBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultBedBoardBaselineAdjuster: DefaultBedBoardBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelDefaultBedBoardBaselineAdjuster: DefaultBedBoardBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultBedBoardBaselineAdjuster: DefaultBedBoardBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultBedBoardBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default bed board baseline steps in order and keeps a trace of each.
    final class DefaultBedBoardBaselineEngine {
        var steps: [any DefaultBedBoardBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultBedBoardBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultBedBoardBaseline) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [DefaultBedBoardBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultBedBoardBaselineEngine() -> DefaultBedBoardBaselineEngine {
        return DefaultBedBoardBaselineEngine(
            steps: [
                MinimumDefaultBedBoardBaselineAdjuster(minimum: 11.3),
                DefaultBedBoardBaselineGraceDaysOffsetAdjuster(weight: 1.93),
                TieredDefaultBedBoardBaselineAdjuster(bounds: [1957.0, 2534.0, 5545.0], rates: [1.11, 1.17, 1.1]),
                RoundingDefaultBedBoardBaselineAdjuster(step: 0.5),
                ChannelDefaultBedBoardBaselineAdjuster(factors: ["online": 1.24, "central": 0.96]),
                PercentDefaultBedBoardBaselineAdjuster(percent: 8.4),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 72501.3
        )
    }
}
