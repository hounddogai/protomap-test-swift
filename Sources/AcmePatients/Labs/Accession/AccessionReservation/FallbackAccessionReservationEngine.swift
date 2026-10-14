import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback accession reservation calculation.
    protocol FallbackAccessionReservationStep {
        func describe() -> String
        func adjust(_ item: FallbackAccessionReservation, value: Double) -> Double
    }

    final class RoundingFallbackAccessionReservationAdjuster: FallbackAccessionReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAccessionReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFallbackAccessionReservationAdjuster: FallbackAccessionReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackAccessionReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackAccessionReservationAdjuster: FallbackAccessionReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAccessionReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback accession reservation steps in order and keeps a trace of each.
    final class FallbackAccessionReservationEngine {
        var steps: [any FallbackAccessionReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAccessionReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAccessionReservation) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAccessionReservationStep = steps[index]
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

        func evaluateAll(_ items: [FallbackAccessionReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAccessionReservationEngine() -> FallbackAccessionReservationEngine {
        return FallbackAccessionReservationEngine(
            steps: [
                RoundingFallbackAccessionReservationAdjuster(step: 0.05),
                PercentFallbackAccessionReservationAdjuster(percent: -18.9),
                TieredFallbackAccessionReservationAdjuster(
                    bounds: [1379.0, 5089.0, 6093.0, 8719.0],
                    rates: [1.06, 0.9, 1.11, 1.12]
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 51797.8
        )
    }
}
