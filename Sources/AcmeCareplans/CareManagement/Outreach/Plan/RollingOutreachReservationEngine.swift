import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling outreach reservation calculation.
    protocol RollingOutreachReservationAdjuster {
        func describe() -> String
        func adjust(_ item: RollingOutreachReservation, value: Double) -> Double
    }

    final class MinimumRollingOutreachReservationAdjuster: RollingOutreachReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingOutreachReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelRollingOutreachReservationAdjuster: RollingOutreachReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingOutreachReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRollingOutreachReservationAdjuster: RollingOutreachReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingOutreachReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingOutreachReservationAdjuster: RollingOutreachReservationAdjuster {
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

        func adjust(_ item: RollingOutreachReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling outreach reservation steps in order and keeps a trace of each.
    final class RollingOutreachReservationEngine {
        var steps: [any RollingOutreachReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingOutreachReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingOutreachReservation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingOutreachReservationAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RollingOutreachReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingOutreachReservationEngine(_ flags: Kit.Flags.Registry) -> RollingOutreachReservationEngine {
        return RollingOutreachReservationEngine(
            steps: [
                MinimumRollingOutreachReservationAdjuster(minimum: 17.8),
                LabelRollingOutreachReservationAdjuster(factors: ["central": 1.04, "north": 0.85]),
                RoundingRollingOutreachReservationAdjuster(step: 0.05),
                FlaggedRollingOutreachReservationAdjuster(
                    flags: flags,
                    flag: "rolling-outreach-reservation-pending",
                    percent: -8.6
                ),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 69051.1
        )
    }
}
