import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier entry calculation.
    protocol CourierEntryStep {
        func describe() -> String
        func adjust(_ item: CourierEntry, value: Double) -> Double
    }

    final class MinimumCourierEntryAdjuster: CourierEntryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCourierEntryAdjuster: CourierEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCourierEntryAdjuster: CourierEntryStep {
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

        func adjust(_ item: CourierEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCourierEntryAdjuster: CourierEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CourierEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the courier entry steps in order and keeps a trace of each.
    final class CourierEntryEngine {
        var steps: [any CourierEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierEntry) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [CourierEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierEntryEngine(_ flags: Kit.Flags.Registry) -> CourierEntryEngine {
        return CourierEntryEngine(
            steps: [
                MinimumCourierEntryAdjuster(minimum: 34.2),
                RoundingCourierEntryAdjuster(step: 0.5),
                FlaggedCourierEntryAdjuster(flags: flags, flag: "courier-entry-lenient", percent: 6.9),
                TitleCourierEntryAdjuster(factors: ["north": 1.36]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 17851.1
        )
    }
}
