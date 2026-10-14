import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default census reservation calculation.
    protocol DefaultCensusReservationFactor {
        func describe() -> String
        func adjust(_ item: DefaultCensusReservation, value: Double) -> Double
    }

    final class MinimumDefaultCensusReservationAdjuster: DefaultCensusReservationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCensusReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultCensusReservationAdjuster: DefaultCensusReservationFactor {
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

        func adjust(_ item: DefaultCensusReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultCensusReservationMarginOffsetAdjuster: DefaultCensusReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: DefaultCensusReservation, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class PercentDefaultCensusReservationAdjuster: DefaultCensusReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCensusReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default census reservation steps in order and keeps a trace of each.
    final class DefaultCensusReservationEngine {
        var steps: [any DefaultCensusReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCensusReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultCensusReservation) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [DefaultCensusReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultCensusReservationEngine(_ flags: Kit.Flags.Registry) -> DefaultCensusReservationEngine {
        return DefaultCensusReservationEngine(
            steps: [
                MinimumDefaultCensusReservationAdjuster(minimum: 32.0),
                FlaggedDefaultCensusReservationAdjuster(
                    flags: flags,
                    flag: "default-census-reservation-regional",
                    percent: 3.4
                ),
                DefaultCensusReservationMarginOffsetAdjuster(weight: 1.82),
                PercentDefaultCensusReservationAdjuster(percent: 3.1),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 97730.2
        )
    }
}
