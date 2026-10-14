import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered skill mix reservation calculation.
    protocol TieredSkillMixReservationAdjuster {
        func describe() -> String
        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double
    }

    final class TieredTieredSkillMixReservationAdjuster: TieredSkillMixReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTieredSkillMixReservationAdjuster: TieredSkillMixReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleTieredSkillMixReservationAdjuster: TieredSkillMixReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredSkillMixReservationAdjuster: TieredSkillMixReservationAdjuster {
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

        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredSkillMixReservationAdjuster: TieredSkillMixReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSkillMixReservationGraceDaysOffsetAdjuster: TieredSkillMixReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: TieredSkillMixReservation, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the tiered skill mix reservation steps in order and keeps a trace of each.
    final class TieredSkillMixReservationEngine {
        var steps: [any TieredSkillMixReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredSkillMixReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredSkillMixReservation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredSkillMixReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredSkillMixReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredSkillMixReservationEngine(_ flags: Kit.Flags.Registry) -> TieredSkillMixReservationEngine {
        return TieredSkillMixReservationEngine(
            steps: [
                TieredTieredSkillMixReservationAdjuster(
                    bounds: [3543.0, 4450.0, 8466.0, 8599.0],
                    rates: [0.81, 0.87, 0.87, 0.83]
                ),
                CapTieredSkillMixReservationAdjuster(cap: 8486.0),
                TitleTieredSkillMixReservationAdjuster(factors: ["retail": 0.86, "east": 1.1]),
                FlaggedTieredSkillMixReservationAdjuster(
                    flags: flags,
                    flag: "tiered-skill-mix-reservation-rolling",
                    percent: 2.2
                ),
                MinimumTieredSkillMixReservationAdjuster(minimum: 0.7),
                TieredSkillMixReservationGraceDaysOffsetAdjuster(weight: 0.92),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 98545.0
        )
    }
}
