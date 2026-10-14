import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive specimen reservation calculation.
    protocol AdaptiveSpecimenReservationAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveSpecimenReservation, value: Double) -> Double
    }

    final class CapAdaptiveSpecimenReservationAdjuster: AdaptiveSpecimenReservationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveSpecimenReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAdaptiveSpecimenReservationAdjuster: AdaptiveSpecimenReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveSpecimenReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveSpecimenReservationAdjuster: AdaptiveSpecimenReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveSpecimenReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveSpecimenReservationAdjuster: AdaptiveSpecimenReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveSpecimenReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive specimen reservation steps in order and keeps a trace of each.
    final class AdaptiveSpecimenReservationEngine {
        var steps: [any AdaptiveSpecimenReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSpecimenReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveSpecimenReservation) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveSpecimenReservationAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveSpecimenReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSpecimenReservationEngine() -> AdaptiveSpecimenReservationEngine {
        return AdaptiveSpecimenReservationEngine(
            steps: [
                CapAdaptiveSpecimenReservationAdjuster(cap: 49984.0),
                TieredAdaptiveSpecimenReservationAdjuster(bounds: [4930.0, 5510.0], rates: [0.99, 0.9]),
                PercentAdaptiveSpecimenReservationAdjuster(percent: 20.6),
                MinimumAdaptiveSpecimenReservationAdjuster(minimum: 15.8),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 89797.0
        )
    }
}
