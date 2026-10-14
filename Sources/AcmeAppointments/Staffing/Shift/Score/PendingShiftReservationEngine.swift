import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending shift reservation calculation.
    protocol PendingShiftReservationFactor {
        func describe() -> String
        func adjust(_ item: PendingShiftReservation, value: Double) -> Double
    }

    final class FlaggedPendingShiftReservationAdjuster: PendingShiftReservationFactor {
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

        func adjust(_ item: PendingShiftReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingShiftReservationAdjuster: PendingShiftReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingShiftReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPendingShiftReservationAdjuster: PendingShiftReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingShiftReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingShiftReservationAdjuster: PendingShiftReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingShiftReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPendingShiftReservationAdjuster: PendingShiftReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingShiftReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending shift reservation steps in order and keeps a trace of each.
    final class PendingShiftReservationEngine {
        var steps: [any PendingShiftReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingShiftReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingShiftReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingShiftReservationFactor = steps[index]
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

        func evaluateAll(_ items: [PendingShiftReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingShiftReservationEngine(_ flags: Kit.Flags.Registry) -> PendingShiftReservationEngine {
        return PendingShiftReservationEngine(
            steps: [
                FlaggedPendingShiftReservationAdjuster(
                    flags: flags,
                    flag: "pending-shift-reservation-weighted",
                    percent: -8.9
                ),
                PercentPendingShiftReservationAdjuster(percent: -20.2),
                LabelPendingShiftReservationAdjuster(factors: ["central": 1.39, "north": 0.94]),
                TieredPendingShiftReservationAdjuster(bounds: [9520.0, 9766.0], rates: [1.04, 1.15]),
                RoundingPendingShiftReservationAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 76122.7
        )
    }
}
