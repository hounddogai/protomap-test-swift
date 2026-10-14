import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary schedule calculation.
    protocol FormularyScheduleStep {
        func describe() -> String
        func adjust(_ item: FormularySchedule, value: Double) -> Double
    }

    final class CapFormularyScheduleAdjuster: FormularyScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFormularyScheduleAdjuster: FormularyScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFormularyScheduleAdjuster: FormularyScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFormularyScheduleAdjuster: FormularyScheduleStep {
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

        func adjust(_ item: FormularySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FormularyScheduleQuantityOffsetAdjuster: FormularyScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FormularySchedule, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the formulary schedule steps in order and keeps a trace of each.
    final class FormularyScheduleEngine {
        var steps: [any FormularyScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FormularySchedule) -> Double {
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

        func evaluateAll(_ items: [FormularySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFormularyScheduleEngine(_ flags: Kit.Flags.Registry) -> FormularyScheduleEngine {
        return FormularyScheduleEngine(
            steps: [
                CapFormularyScheduleAdjuster(cap: 47671.0),
                MinimumFormularyScheduleAdjuster(minimum: 27.1),
                PercentFormularyScheduleAdjuster(percent: 23.0),
                FlaggedFormularyScheduleAdjuster(flags: flags, flag: "formulary-schedule-global", percent: -2.0),
                FormularyScheduleQuantityOffsetAdjuster(weight: 0.29),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 92435.5
        )
    }
}
