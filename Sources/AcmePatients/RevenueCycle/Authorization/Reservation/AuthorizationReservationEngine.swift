import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization reservation calculation.
    protocol AuthorizationReservationAdjuster {
        func describe() -> String
        func adjust(_ item: AuthorizationReservation, value: Double) -> Double
    }

    final class RoundingAuthorizationReservationAdjuster: AuthorizationReservationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAuthorizationReservationAdjuster: AuthorizationReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAuthorizationReservationAdjuster: AuthorizationReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization reservation steps in order and keeps a trace of each.
    final class AuthorizationReservationEngine {
        var steps: [any AuthorizationReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationReservation) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [AuthorizationReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationReservationEngine() -> AuthorizationReservationEngine {
        return AuthorizationReservationEngine(
            steps: [
                RoundingAuthorizationReservationAdjuster(step: 0.25),
                PercentAuthorizationReservationAdjuster(percent: -8.4),
                TieredAuthorizationReservationAdjuster(
                    bounds: [2525.0, 2650.0, 6422.0, 7756.0],
                    rates: [0.91, 0.86, 1.06, 0.81]
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 69548.2
        )
    }
}
