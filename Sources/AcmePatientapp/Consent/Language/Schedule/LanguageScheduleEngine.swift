import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language schedule calculation.
    protocol LanguageScheduleFactor {
        func describe() -> String
        func adjust(_ item: LanguageSchedule, value: Double) -> Double
    }

    final class CapLanguageScheduleAdjuster: LanguageScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelLanguageScheduleAdjuster: LanguageScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LanguageSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLanguageScheduleAdjuster: LanguageScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLanguageScheduleAdjuster: LanguageScheduleFactor {
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

        func adjust(_ item: LanguageSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageScheduleLimitOffsetAdjuster: LanguageScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: LanguageSchedule, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentLanguageScheduleAdjuster: LanguageScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language schedule steps in order and keeps a trace of each.
    final class LanguageScheduleEngine {
        var steps: [any LanguageScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LanguageSchedule) -> Double {
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

        func evaluateAll(_ items: [LanguageSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLanguageScheduleEngine(_ flags: Kit.Flags.Registry) -> LanguageScheduleEngine {
        return LanguageScheduleEngine(
            steps: [
                CapLanguageScheduleAdjuster(cap: 41118.0),
                LabelLanguageScheduleAdjuster(factors: ["north": 1.19, "east": 0.86]),
                MinimumLanguageScheduleAdjuster(minimum: 12.3),
                FlaggedLanguageScheduleAdjuster(flags: flags, flag: "language-schedule-seasonal", percent: 3.7),
                LanguageScheduleLimitOffsetAdjuster(weight: 1.86),
                PercentLanguageScheduleAdjuster(percent: 13.9),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 67223.9
        )
    }
}
