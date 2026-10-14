import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift reservation calculation.
    protocol ShiftReservationModifier {
        func describe() -> String
        func adjust(_ item: ShiftReservation, value: Double) -> Double
    }

    final class FlaggedShiftReservationAdjuster: ShiftReservationModifier {
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

        func adjust(_ item: ShiftReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingShiftReservationAdjuster: ShiftReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredShiftReservationAdjuster: ShiftReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelShiftReservationAdjuster: ShiftReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ShiftReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentShiftReservationAdjuster: ShiftReservationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the shift reservation steps in order and keeps a trace of each.
    final class ShiftReservationEngine {
        var steps: [any ShiftReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftReservation) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftReservationModifier = steps[index]
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

        func evaluateAll(_ items: [ShiftReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftReservationEngine(_ flags: Kit.Flags.Registry) -> ShiftReservationEngine {
        return ShiftReservationEngine(
            steps: [
                FlaggedShiftReservationAdjuster(flags: flags, flag: "shift-reservation-default", percent: 7.5),
                RoundingShiftReservationAdjuster(step: 0.1),
                TieredShiftReservationAdjuster(bounds: [2987.0, 7057.0], rates: [1.06, 1.11]),
                LabelShiftReservationAdjuster(factors: ["central": 1.24, "online": 0.78, "north": 1.11]),
                PercentShiftReservationAdjuster(percent: -19.7),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 37379.8
        )
    }
}
