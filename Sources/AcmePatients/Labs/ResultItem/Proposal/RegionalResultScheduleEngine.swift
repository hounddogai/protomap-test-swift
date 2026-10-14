import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional result schedule calculation.
    protocol RegionalResultScheduleModifier {
        func describe() -> String
        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double
    }

    final class CapRegionalResultScheduleAdjuster: RegionalResultScheduleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalResultScheduleAdjuster: RegionalResultScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalResultScheduleAdjuster: RegionalResultScheduleModifier {
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

        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalResultScheduleAdjuster: RegionalResultScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRegionalResultScheduleAdjuster: RegionalResultScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRegionalResultScheduleAdjuster: RegionalResultScheduleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalResultSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional result schedule steps in order and keeps a trace of each.
    final class RegionalResultScheduleEngine {
        var steps: [any RegionalResultScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalResultScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalResultSchedule) -> Double {
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

        func evaluateAll(_ items: [RegionalResultSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalResultScheduleEngine(_ flags: Kit.Flags.Registry) -> RegionalResultScheduleEngine {
        return RegionalResultScheduleEngine(
            steps: [
                CapRegionalResultScheduleAdjuster(cap: 49423.0),
                RoundingRegionalResultScheduleAdjuster(step: 1.0),
                FlaggedRegionalResultScheduleAdjuster(
                    flags: flags,
                    flag: "regional-result-schedule-lenient",
                    percent: -0.2
                ),
                MinimumRegionalResultScheduleAdjuster(minimum: 18.3),
                PercentRegionalResultScheduleAdjuster(percent: -23.7),
                NameRegionalResultScheduleAdjuster(factors: ["retail": 1.11]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 46980.5
        )
    }
}
