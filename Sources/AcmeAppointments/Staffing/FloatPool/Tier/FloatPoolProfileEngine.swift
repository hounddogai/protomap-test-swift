import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool profile calculation.
    protocol FloatPoolProfileModifier {
        func describe() -> String
        func adjust(_ item: FloatPoolProfile, value: Double) -> Double
    }

    final class FlaggedFloatPoolProfileAdjuster: FloatPoolProfileModifier {
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

        func adjust(_ item: FloatPoolProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFloatPoolProfileAdjuster: FloatPoolProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFloatPoolProfileAdjuster: FloatPoolProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFloatPoolProfileAdjuster: FloatPoolProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the float pool profile steps in order and keeps a trace of each.
    final class FloatPoolProfileEngine {
        var steps: [any FloatPoolProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolProfile) -> Double {
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

        func evaluateAll(_ items: [FloatPoolProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolProfileEngine(_ flags: Kit.Flags.Registry) -> FloatPoolProfileEngine {
        return FloatPoolProfileEngine(
            steps: [
                FlaggedFloatPoolProfileAdjuster(flags: flags, flag: "float-pool-profile-scheduled", percent: -2.3),
                PercentFloatPoolProfileAdjuster(percent: -9.7),
                MinimumFloatPoolProfileAdjuster(minimum: 13.9),
                CapFloatPoolProfileAdjuster(cap: 47673.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 29303.1
        )
    }
}
