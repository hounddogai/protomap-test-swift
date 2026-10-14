import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending follow up reservation calculation.
    protocol PendingFollowUpReservationFactor {
        func describe() -> String
        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double
    }

    final class PercentPendingFollowUpReservationAdjuster: PendingFollowUpReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingFollowUpReservationCreatedAtOffsetAdjuster: PendingFollowUpReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FacilityPendingFollowUpReservationAdjuster: PendingFollowUpReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPendingFollowUpReservationAdjuster: PendingFollowUpReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingFollowUpReservationAdjuster: PendingFollowUpReservationFactor {
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

        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingFollowUpReservationAdjuster: PendingFollowUpReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingFollowUpReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending follow up reservation steps in order and keeps a trace of each.
    final class PendingFollowUpReservationEngine {
        var steps: [any PendingFollowUpReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFollowUpReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingFollowUpReservation) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFollowUpReservationFactor = steps[index]
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

        func evaluateAll(_ items: [PendingFollowUpReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingFollowUpReservationEngine(_ flags: Kit.Flags.Registry) -> PendingFollowUpReservationEngine {
        return PendingFollowUpReservationEngine(
            steps: [
                PercentPendingFollowUpReservationAdjuster(percent: 11.9),
                PendingFollowUpReservationCreatedAtOffsetAdjuster(weight: 0.49),
                FacilityPendingFollowUpReservationAdjuster(factors: ["south": 1.34, "online": 0.99]),
                CapPendingFollowUpReservationAdjuster(cap: 47325.0),
                FlaggedPendingFollowUpReservationAdjuster(
                    flags: flags,
                    flag: "pending-follow-up-reservation-weighted",
                    percent: -1.3
                ),
                RoundingPendingFollowUpReservationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 25816.8
        )
    }
}
