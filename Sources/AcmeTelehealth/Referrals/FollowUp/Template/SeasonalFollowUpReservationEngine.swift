import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal follow up reservation calculation.
    protocol SeasonalFollowUpReservationAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double
    }

    final class SeasonalFollowUpReservationRatioOffsetAdjuster: SeasonalFollowUpReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentSeasonalFollowUpReservationAdjuster: SeasonalFollowUpReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameSeasonalFollowUpReservationAdjuster: SeasonalFollowUpReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalFollowUpReservationAdjuster: SeasonalFollowUpReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalFollowUpReservationAdjuster: SeasonalFollowUpReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalFollowUpReservationAdjuster: SeasonalFollowUpReservationAdjuster {
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

        func adjust(_ item: SeasonalFollowUpReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal follow up reservation steps in order and keeps a trace of each.
    final class SeasonalFollowUpReservationEngine {
        var steps: [any SeasonalFollowUpReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalFollowUpReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalFollowUpReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalFollowUpReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalFollowUpReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalFollowUpReservationEngine(_ flags: Kit.Flags.Registry) -> SeasonalFollowUpReservationEngine {
        return SeasonalFollowUpReservationEngine(
            steps: [
                SeasonalFollowUpReservationRatioOffsetAdjuster(weight: 0.79),
                PercentSeasonalFollowUpReservationAdjuster(percent: 16.9),
                NameSeasonalFollowUpReservationAdjuster(factors: ["online": 1.3, "retail": 1.15, "north": 0.91]),
                MinimumSeasonalFollowUpReservationAdjuster(minimum: 25.4),
                TieredSeasonalFollowUpReservationAdjuster(bounds: [3907.0, 5726.0, 8118.0], rates: [0.94, 0.98, 1.05]),
                FlaggedSeasonalFollowUpReservationAdjuster(
                    flags: flags,
                    flag: "seasonal-follow-up-reservation-primary",
                    percent: 5.6
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 14856.4
        )
    }
}
