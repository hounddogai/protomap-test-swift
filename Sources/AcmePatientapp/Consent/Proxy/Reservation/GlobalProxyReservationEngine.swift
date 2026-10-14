import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global proxy reservation calculation.
    protocol GlobalProxyReservationModifier {
        func describe() -> String
        func adjust(_ item: GlobalProxyReservation, value: Double) -> Double
    }

    final class CapGlobalProxyReservationAdjuster: GlobalProxyReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalProxyReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalProxyReservationAdjuster: GlobalProxyReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalProxyReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGlobalProxyReservationAdjuster: GlobalProxyReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalProxyReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalProxyReservationCopayOffsetAdjuster: GlobalProxyReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: GlobalProxyReservation, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the global proxy reservation steps in order and keeps a trace of each.
    final class GlobalProxyReservationEngine {
        var steps: [any GlobalProxyReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalProxyReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalProxyReservation) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalProxyReservationModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalProxyReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalProxyReservationEngine() -> GlobalProxyReservationEngine {
        return GlobalProxyReservationEngine(
            steps: [
                CapGlobalProxyReservationAdjuster(cap: 6348.0),
                RoundingGlobalProxyReservationAdjuster(step: 0.5),
                TieredGlobalProxyReservationAdjuster(bounds: [4700.0, 8496.0, 8817.0], rates: [1.17, 0.97, 0.92]),
                GlobalProxyReservationCopayOffsetAdjuster(weight: 0.04),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 18083.5
        )
    }
}
