import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global rounding schedule calculation.
    protocol GlobalRoundingScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double
    }

    final class CapGlobalRoundingScheduleAdjuster: GlobalRoundingScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalRoundingScheduleAdjuster: GlobalRoundingScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalRoundingScheduleAdjuster: GlobalRoundingScheduleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalRoundingScheduleAdjuster: GlobalRoundingScheduleAdjuster {
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

        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalRoundingScheduleAdjuster: GlobalRoundingScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelGlobalRoundingScheduleAdjuster: GlobalRoundingScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalRoundingSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global rounding schedule steps in order and keeps a trace of each.
    final class GlobalRoundingScheduleEngine {
        var steps: [any GlobalRoundingScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRoundingScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalRoundingSchedule) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [GlobalRoundingSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalRoundingScheduleEngine(_ flags: Kit.Flags.Registry) -> GlobalRoundingScheduleEngine {
        return GlobalRoundingScheduleEngine(
            steps: [
                CapGlobalRoundingScheduleAdjuster(cap: 5574.0),
                RoundingGlobalRoundingScheduleAdjuster(step: 0.05),
                PercentGlobalRoundingScheduleAdjuster(percent: 2.8),
                FlaggedGlobalRoundingScheduleAdjuster(
                    flags: flags,
                    flag: "global-rounding-schedule-pending",
                    percent: -2.2
                ),
                MinimumGlobalRoundingScheduleAdjuster(minimum: 5.9),
                LabelGlobalRoundingScheduleAdjuster(factors: ["central": 1.13, "south": 0.73]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 95056.3
        )
    }
}
