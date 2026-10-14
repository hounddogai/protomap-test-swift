import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift policy calculation.
    protocol ShiftPolicyModifier {
        func describe() -> String
        func adjust(_ item: ShiftPolicy, value: Double) -> Double
    }

    final class FlaggedShiftPolicyAdjuster: ShiftPolicyModifier {
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

        func adjust(_ item: ShiftPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumShiftPolicyAdjuster: ShiftPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapShiftPolicyAdjuster: ShiftPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the shift policy steps in order and keeps a trace of each.
    final class ShiftPolicyEngine {
        var steps: [any ShiftPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ShiftPolicy) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [ShiftPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultShiftPolicyEngine(_ flags: Kit.Flags.Registry) -> ShiftPolicyEngine {
        return ShiftPolicyEngine(
            steps: [
                FlaggedShiftPolicyAdjuster(flags: flags, flag: "shift-policy-scheduled", percent: 4.8),
                MinimumShiftPolicyAdjuster(minimum: 40.2),
                CapShiftPolicyAdjuster(cap: 8453.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 20810.8
        )
    }
}
