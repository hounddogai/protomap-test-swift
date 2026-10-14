import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted credential reservation calculation.
    protocol WeightedCredentialReservationModifier {
        func describe() -> String
        func adjust(_ item: WeightedCredentialReservation, value: Double) -> Double
    }

    final class CountryWeightedCredentialReservationAdjuster: WeightedCredentialReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: WeightedCredentialReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedCredentialReservationAdjuster: WeightedCredentialReservationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedCredentialReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedCredentialReservationAdjuster: WeightedCredentialReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedCredentialReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted credential reservation steps in order and keeps a trace of each.
    final class WeightedCredentialReservationEngine {
        var steps: [any WeightedCredentialReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCredentialReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedCredentialReservation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedCredentialReservationModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedCredentialReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedCredentialReservationEngine() -> WeightedCredentialReservationEngine {
        return WeightedCredentialReservationEngine(
            steps: [
                CountryWeightedCredentialReservationAdjuster(factors: ["retail": 1.04, "east": 0.72, "north": 0.79]),
                PercentWeightedCredentialReservationAdjuster(percent: -10.9),
                CapWeightedCredentialReservationAdjuster(cap: 45696.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 2847.2
        )
    }
}
