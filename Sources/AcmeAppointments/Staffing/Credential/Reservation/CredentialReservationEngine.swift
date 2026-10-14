import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential reservation calculation.
    protocol CredentialReservationFactor {
        func describe() -> String
        func adjust(_ item: CredentialReservation, value: Double) -> Double
    }

    final class CapCredentialReservationAdjuster: CredentialReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCredentialReservationAdjuster: CredentialReservationFactor {
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

        func adjust(_ item: CredentialReservation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCredentialReservationAdjuster: CredentialReservationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CredentialReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCredentialReservationAdjuster: CredentialReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCredentialReservationAdjuster: CredentialReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the credential reservation steps in order and keeps a trace of each.
    final class CredentialReservationEngine {
        var steps: [any CredentialReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CredentialReservation) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialReservationFactor = steps[index]
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

        func evaluateAll(_ items: [CredentialReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCredentialReservationEngine(_ flags: Kit.Flags.Registry) -> CredentialReservationEngine {
        return CredentialReservationEngine(
            steps: [
                CapCredentialReservationAdjuster(cap: 3524.0),
                FlaggedCredentialReservationAdjuster(
                    flags: flags,
                    flag: "credential-reservation-weighted",
                    percent: 0.6
                ),
                TitleCredentialReservationAdjuster(factors: ["online": 1.05, "central": 1.33]),
                TieredCredentialReservationAdjuster(bounds: [2146.0, 3725.0, 6577.0], rates: [0.86, 1.19, 0.92]),
                RoundingCredentialReservationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 73033.5
        )
    }
}
