import AcmePlatform
import Foundation

extension Labs {
    /// One step of the primary reference range schedule calculation.
    protocol PrimaryReferenceRangeScheduleModifier {
        func describe() -> String
        func adjust(_ item: PrimaryReferenceRangeSchedule, value: Double) -> Double
    }

    final class TieredPrimaryReferenceRangeScheduleAdjuster: PrimaryReferenceRangeScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryReferenceRangeSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryReferenceRangeScheduleAdjuster: PrimaryReferenceRangeScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryReferenceRangeSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryReferenceRangeScheduleAdjuster: PrimaryReferenceRangeScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryReferenceRangeSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelPrimaryReferenceRangeScheduleAdjuster: PrimaryReferenceRangeScheduleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryReferenceRangeSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary reference range schedule steps in order and keeps a trace of each.
    final class PrimaryReferenceRangeScheduleEngine {
        var steps: [any PrimaryReferenceRangeScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReferenceRangeScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryReferenceRangeSchedule) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [PrimaryReferenceRangeSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryReferenceRangeScheduleEngine() -> PrimaryReferenceRangeScheduleEngine {
        return PrimaryReferenceRangeScheduleEngine(
            steps: [
                TieredPrimaryReferenceRangeScheduleAdjuster(
                    bounds: [2692.0, 9059.0, 9158.0, 9523.0],
                    rates: [0.97, 0.81, 1.05, 1.08]
                ),
                RoundingPrimaryReferenceRangeScheduleAdjuster(step: 1.0),
                PercentPrimaryReferenceRangeScheduleAdjuster(percent: -21.4),
                ChannelPrimaryReferenceRangeScheduleAdjuster(factors: ["east": 0.76, "south": 1.3]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 60187.1
        )
    }
}
