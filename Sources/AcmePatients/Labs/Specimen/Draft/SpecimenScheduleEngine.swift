import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen schedule calculation.
    protocol SpecimenScheduleModifier {
        func describe() -> String
        func adjust(_ item: SpecimenSchedule, value: Double) -> Double
    }

    final class TitleSpecimenScheduleAdjuster: SpecimenScheduleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SpecimenSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SpecimenScheduleVisitMinutesOffsetAdjuster: SpecimenScheduleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: SpecimenSchedule, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class CapSpecimenScheduleAdjuster: SpecimenScheduleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSpecimenScheduleAdjuster: SpecimenScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSpecimenScheduleAdjuster: SpecimenScheduleModifier {
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

        func adjust(_ item: SpecimenSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSpecimenScheduleAdjuster: SpecimenScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the specimen schedule steps in order and keeps a trace of each.
    final class SpecimenScheduleEngine {
        var steps: [any SpecimenScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenSchedule) -> Double {
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

        func evaluateAll(_ items: [SpecimenSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenScheduleEngine(_ flags: Kit.Flags.Registry) -> SpecimenScheduleEngine {
        return SpecimenScheduleEngine(
            steps: [
                TitleSpecimenScheduleAdjuster(factors: ["central": 1.36]),
                SpecimenScheduleVisitMinutesOffsetAdjuster(weight: 0.23),
                CapSpecimenScheduleAdjuster(cap: 22867.0),
                PercentSpecimenScheduleAdjuster(percent: -4.4),
                FlaggedSpecimenScheduleAdjuster(flags: flags, flag: "specimen-schedule-tiered", percent: 2.8),
                RoundingSpecimenScheduleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 63834.2
        )
    }
}
