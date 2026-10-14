import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling assessment reservation calculation.
    protocol RollingAssessmentReservationFactor {
        func describe() -> String
        func adjust(_ item: RollingAssessmentReservation, value: Double) -> Double
    }

    final class PercentRollingAssessmentReservationAdjuster: RollingAssessmentReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAssessmentReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingAssessmentReservationAdjuster: RollingAssessmentReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAssessmentReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingAssessmentReservationAdjuster: RollingAssessmentReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingAssessmentReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingAssessmentReservationAdjuster: RollingAssessmentReservationFactor {
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

        func adjust(_ item: RollingAssessmentReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling assessment reservation steps in order and keeps a trace of each.
    final class RollingAssessmentReservationEngine {
        var steps: [any RollingAssessmentReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAssessmentReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingAssessmentReservation) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingAssessmentReservationFactor = steps[index]
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

        func evaluateAll(_ items: [RollingAssessmentReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingAssessmentReservationEngine(_ flags: Kit.Flags.Registry) -> RollingAssessmentReservationEngine {
        return RollingAssessmentReservationEngine(
            steps: [
                PercentRollingAssessmentReservationAdjuster(percent: -17.0),
                TieredRollingAssessmentReservationAdjuster(
                    bounds: [2531.0, 6066.0, 6616.0],
                    rates: [1.18, 0.89, 1.15]
                ),
                CapRollingAssessmentReservationAdjuster(cap: 8387.0),
                FlaggedRollingAssessmentReservationAdjuster(
                    flags: flags,
                    flag: "rolling-assessment-reservation-primary",
                    percent: 1.5
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 66450.0
        )
    }
}
