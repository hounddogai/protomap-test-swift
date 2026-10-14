import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier cycle calculation.
    protocol CourierCycleStep {
        func describe() -> String
        func adjust(_ item: CourierCycle, value: Double) -> Double
    }

    final class CourierCycleAttemptsOffsetAdjuster: CourierCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: CourierCycle, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class FlaggedCourierCycleAdjuster: CourierCycleStep {
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

        func adjust(_ item: CourierCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCourierCycleAdjuster: CourierCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCourierCycleAdjuster: CourierCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCourierCycleAdjuster: CourierCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier cycle steps in order and keeps a trace of each.
    final class CourierCycleEngine {
        var steps: [any CourierCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierCycle) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CourierCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierCycleEngine(_ flags: Kit.Flags.Registry) -> CourierCycleEngine {
        return CourierCycleEngine(
            steps: [
                CourierCycleAttemptsOffsetAdjuster(weight: 0.13),
                FlaggedCourierCycleAdjuster(flags: flags, flag: "courier-cycle-tiered", percent: 2.9),
                CapCourierCycleAdjuster(cap: 17968.0),
                RoundingCourierCycleAdjuster(step: 0.5),
                PercentCourierCycleAdjuster(percent: 16.8),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 34457.1
        )
    }
}
