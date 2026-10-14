import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending overtime reservation calculation.
    protocol PendingOvertimeReservationAdjuster {
        func describe() -> String
        func adjust(_ item: PendingOvertimeReservation, value: Double) -> Double
    }

    final class TieredPendingOvertimeReservationAdjuster: PendingOvertimeReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingOvertimeReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingOvertimeReservationAdjuster: PendingOvertimeReservationAdjuster {
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

        func adjust(_ item: PendingOvertimeReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingOvertimeReservationAdjuster: PendingOvertimeReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingOvertimeReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingOvertimeReservationRatioOffsetAdjuster: PendingOvertimeReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: PendingOvertimeReservation, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingPendingOvertimeReservationAdjuster: PendingOvertimeReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingOvertimeReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending overtime reservation steps in order and keeps a trace of each.
    final class PendingOvertimeReservationEngine {
        var steps: [any PendingOvertimeReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingOvertimeReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingOvertimeReservation) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingOvertimeReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingOvertimeReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingOvertimeReservationEngine(_ flags: Kit.Flags.Registry) -> PendingOvertimeReservationEngine {
        return PendingOvertimeReservationEngine(
            steps: [
                TieredPendingOvertimeReservationAdjuster(bounds: [2149.0, 2752.0, 4840.0], rates: [1.03, 1.05, 1.03]),
                FlaggedPendingOvertimeReservationAdjuster(
                    flags: flags,
                    flag: "pending-overtime-reservation-seasonal",
                    percent: -6.7
                ),
                PercentPendingOvertimeReservationAdjuster(percent: -14.8),
                PendingOvertimeReservationRatioOffsetAdjuster(weight: 1.56),
                RoundingPendingOvertimeReservationAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 73462.8
        )
    }
}
