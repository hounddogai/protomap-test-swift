import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict isolation schedule calculation.
    protocol StrictIsolationScheduleModifier {
        func describe() -> String
        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double
    }

    final class FlaggedStrictIsolationScheduleAdjuster: StrictIsolationScheduleModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictIsolationScheduleAdjuster: StrictIsolationScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictIsolationScheduleAdjuster: StrictIsolationScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictIsolationScheduleScoreOffsetAdjuster: StrictIsolationScheduleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentStrictIsolationScheduleAdjuster: StrictIsolationScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictIsolationScheduleAdjuster: StrictIsolationScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictIsolationSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict isolation schedule steps in order and keeps a trace of each.
    final class StrictIsolationScheduleEngine {
        var steps: [any StrictIsolationScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictIsolationScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictIsolationSchedule) -> Double {
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

        func evaluateAll(_ items: [StrictIsolationSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictIsolationScheduleEngine(_ flags: Kit.Flags.Registry) -> StrictIsolationScheduleEngine {
        return StrictIsolationScheduleEngine(
            steps: [
                FlaggedStrictIsolationScheduleAdjuster(
                    flags: flags,
                    flag: "strict-isolation-schedule-legacy",
                    percent: 3.6
                ),
                TieredStrictIsolationScheduleAdjuster(
                    bounds: [402.0, 473.0, 4864.0, 5458.0],
                    rates: [0.94, 1.1, 1.09, 1.07]
                ),
                MinimumStrictIsolationScheduleAdjuster(minimum: 13.3),
                StrictIsolationScheduleScoreOffsetAdjuster(weight: 1.14),
                PercentStrictIsolationScheduleAdjuster(percent: 6.4),
                RoundingStrictIsolationScheduleAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 4098.5
        )
    }
}
