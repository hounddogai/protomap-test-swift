import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional accession reservation calculation.
    protocol RegionalAccessionReservationFactor {
        func describe() -> String
        func adjust(_ item: RegionalAccessionReservation, value: Double) -> Double
    }

    final class FlaggedRegionalAccessionReservationAdjuster: RegionalAccessionReservationFactor {
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

        func adjust(_ item: RegionalAccessionReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalAccessionReservationAdjuster: RegionalAccessionReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalAccessionReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalAccessionReservationAdjuster: RegionalAccessionReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAccessionReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional accession reservation steps in order and keeps a trace of each.
    final class RegionalAccessionReservationEngine {
        var steps: [any RegionalAccessionReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAccessionReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalAccessionReservation) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalAccessionReservationFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalAccessionReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalAccessionReservationEngine(_ flags: Kit.Flags.Registry) -> RegionalAccessionReservationEngine {
        return RegionalAccessionReservationEngine(
            steps: [
                FlaggedRegionalAccessionReservationAdjuster(
                    flags: flags,
                    flag: "regional-accession-reservation-pending",
                    percent: 2.7
                ),
                TieredRegionalAccessionReservationAdjuster(
                    bounds: [2993.0, 8817.0, 8837.0],
                    rates: [0.98, 1.13, 0.87]
                ),
                PercentRegionalAccessionReservationAdjuster(percent: 24.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 31803.7
        )
    }
}
