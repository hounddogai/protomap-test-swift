import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending cleaning reservation calculation.
    protocol PendingCleaningReservationStep {
        func describe() -> String
        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double
    }

    final class SegmentPendingCleaningReservationAdjuster: PendingCleaningReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingCleaningReservationAdjuster: PendingCleaningReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPendingCleaningReservationAdjuster: PendingCleaningReservationStep {
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

        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingCleaningReservationAdjuster: PendingCleaningReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingCleaningReservationAdjuster: PendingCleaningReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingCleaningReservationAdjuster: PendingCleaningReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCleaningReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending cleaning reservation steps in order and keeps a trace of each.
    final class PendingCleaningReservationEngine {
        var steps: [any PendingCleaningReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCleaningReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingCleaningReservation) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCleaningReservationStep = steps[index]
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

        func evaluateAll(_ items: [PendingCleaningReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingCleaningReservationEngine(_ flags: Kit.Flags.Registry) -> PendingCleaningReservationEngine {
        return PendingCleaningReservationEngine(
            steps: [
                SegmentPendingCleaningReservationAdjuster(factors: ["north": 0.9, "online": 1.04, "east": 1.34]),
                MinimumPendingCleaningReservationAdjuster(minimum: 0.3),
                FlaggedPendingCleaningReservationAdjuster(
                    flags: flags,
                    flag: "pending-cleaning-reservation-rolling",
                    percent: 6.1
                ),
                RoundingPendingCleaningReservationAdjuster(step: 1.0),
                CapPendingCleaningReservationAdjuster(cap: 8714.0),
                PercentPendingCleaningReservationAdjuster(percent: -8.6),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 44908.6
        )
    }
}
