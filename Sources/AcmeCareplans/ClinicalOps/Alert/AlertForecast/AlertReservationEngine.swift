import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert reservation calculation.
    protocol AlertReservationAdjuster {
        func describe() -> String
        func adjust(_ item: AlertReservation, value: Double) -> Double
    }

    final class TieredAlertReservationAdjuster: AlertReservationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAlertReservationAdjuster: AlertReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAlertReservationAdjuster: AlertReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AlertReservationAttemptsOffsetAdjuster: AlertReservationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: AlertReservation, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the alert reservation steps in order and keeps a trace of each.
    final class AlertReservationEngine {
        var steps: [any AlertReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AlertReservation) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [AlertReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAlertReservationEngine() -> AlertReservationEngine {
        return AlertReservationEngine(
            steps: [
                TieredAlertReservationAdjuster(bounds: [9140.0, 9897.0], rates: [0.91, 1.05]),
                MinimumAlertReservationAdjuster(minimum: 22.7),
                PercentAlertReservationAdjuster(percent: -9.5),
                AlertReservationAttemptsOffsetAdjuster(weight: 1.49),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 2406.6
        )
    }
}
