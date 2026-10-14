import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution reservation calculation.
    protocol SubstitutionReservationAdjuster {
        func describe() -> String
        func adjust(_ item: SubstitutionReservation, value: Double) -> Double
    }

    final class FlaggedSubstitutionReservationAdjuster: SubstitutionReservationAdjuster {
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

        func adjust(_ item: SubstitutionReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSubstitutionReservationAdjuster: SubstitutionReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleSubstitutionReservationAdjuster: SubstitutionReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SubstitutionReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the substitution reservation steps in order and keeps a trace of each.
    final class SubstitutionReservationEngine {
        var steps: [any SubstitutionReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SubstitutionReservation) -> Double {
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

        func evaluateAll(_ items: [SubstitutionReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSubstitutionReservationEngine(_ flags: Kit.Flags.Registry) -> SubstitutionReservationEngine {
        return SubstitutionReservationEngine(
            steps: [
                FlaggedSubstitutionReservationAdjuster(
                    flags: flags,
                    flag: "substitution-reservation-fallback",
                    percent: 2.5
                ),
                MinimumSubstitutionReservationAdjuster(minimum: 16.1),
                TitleSubstitutionReservationAdjuster(factors: ["west": 1.13, "east": 0.82]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 25972.0
        )
    }
}
