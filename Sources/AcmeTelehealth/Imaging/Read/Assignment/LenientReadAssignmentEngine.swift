import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient read assignment calculation.
    protocol LenientReadAssignmentFactor {
        func describe() -> String
        func adjust(_ item: LenientReadAssignment, value: Double) -> Double
    }

    final class CapLenientReadAssignmentAdjuster: LenientReadAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientReadAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientReadAssignmentAdjuster: LenientReadAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientReadAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientReadAssignmentAdjuster: LenientReadAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientReadAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientReadAssignmentAttemptsOffsetAdjuster: LenientReadAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LenientReadAssignment, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingLenientReadAssignmentAdjuster: LenientReadAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientReadAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientReadAssignmentAdjuster: LenientReadAssignmentFactor {
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

        func adjust(_ item: LenientReadAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient read assignment steps in order and keeps a trace of each.
    final class LenientReadAssignmentEngine {
        var steps: [any LenientReadAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReadAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientReadAssignment) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [LenientReadAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientReadAssignmentEngine(_ flags: Kit.Flags.Registry) -> LenientReadAssignmentEngine {
        return LenientReadAssignmentEngine(
            steps: [
                CapLenientReadAssignmentAdjuster(cap: 30623.0),
                MinimumLenientReadAssignmentAdjuster(minimum: 6.1),
                PercentLenientReadAssignmentAdjuster(percent: 3.1),
                LenientReadAssignmentAttemptsOffsetAdjuster(weight: 0.62),
                RoundingLenientReadAssignmentAdjuster(step: 0.1),
                FlaggedLenientReadAssignmentAdjuster(
                    flags: flags,
                    flag: "lenient-read-assignment-lenient",
                    percent: -0.4
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 64545.3
        )
    }
}
