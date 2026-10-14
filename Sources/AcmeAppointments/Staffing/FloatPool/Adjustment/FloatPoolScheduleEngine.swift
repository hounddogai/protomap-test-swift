import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool schedule calculation.
    protocol FloatPoolScheduleStep {
        func describe() -> String
        func adjust(_ item: FloatPoolSchedule, value: Double) -> Double
    }

    final class FlaggedFloatPoolScheduleAdjuster: FloatPoolScheduleStep {
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

        func adjust(_ item: FloatPoolSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFloatPoolScheduleAdjuster: FloatPoolScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFloatPoolScheduleAdjuster: FloatPoolScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameFloatPoolScheduleAdjuster: FloatPoolScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FloatPoolSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool schedule steps in order and keeps a trace of each.
    final class FloatPoolScheduleEngine {
        var steps: [any FloatPoolScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolSchedule) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FloatPoolSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolScheduleEngine(_ flags: Kit.Flags.Registry) -> FloatPoolScheduleEngine {
        return FloatPoolScheduleEngine(
            steps: [
                FlaggedFloatPoolScheduleAdjuster(flags: flags, flag: "float-pool-schedule-fallback", percent: 9.2),
                PercentFloatPoolScheduleAdjuster(percent: 0.6),
                CapFloatPoolScheduleAdjuster(cap: 36296.0),
                NameFloatPoolScheduleAdjuster(factors: ["south": 1.31, "online": 0.95]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 6493.5
        )
    }
}
