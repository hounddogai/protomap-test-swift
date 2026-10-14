import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled dispense reservation calculation.
    protocol ScheduledDispenseReservationAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledDispenseReservation, value: Double) -> Double
    }

    final class ScheduledDispenseReservationRetriesOffsetAdjuster: ScheduledDispenseReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ScheduledDispenseReservation, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class PercentScheduledDispenseReservationAdjuster: ScheduledDispenseReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledDispenseReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledDispenseReservationAdjuster: ScheduledDispenseReservationAdjuster {
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

        func adjust(_ item: ScheduledDispenseReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled dispense reservation steps in order and keeps a trace of each.
    final class ScheduledDispenseReservationEngine {
        var steps: [any ScheduledDispenseReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledDispenseReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledDispenseReservation) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledDispenseReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledDispenseReservationEngine(_ flags: Kit.Flags.Registry) -> ScheduledDispenseReservationEngine {
        return ScheduledDispenseReservationEngine(
            steps: [
                ScheduledDispenseReservationRetriesOffsetAdjuster(weight: 1.88),
                PercentScheduledDispenseReservationAdjuster(percent: -20.2),
                FlaggedScheduledDispenseReservationAdjuster(
                    flags: flags,
                    flag: "scheduled-dispense-reservation-strict",
                    percent: 1.0
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 1064.3
        )
    }
}
