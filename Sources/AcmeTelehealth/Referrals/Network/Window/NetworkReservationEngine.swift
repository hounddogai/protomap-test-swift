import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network reservation calculation.
    protocol NetworkReservationStep {
        func describe() -> String
        func adjust(_ item: NetworkReservation, value: Double) -> Double
    }

    final class NetworkReservationGraceDaysOffsetAdjuster: NetworkReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: NetworkReservation, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapNetworkReservationAdjuster: NetworkReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentNetworkReservationAdjuster: NetworkReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleNetworkReservationAdjuster: NetworkReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: NetworkReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the network reservation steps in order and keeps a trace of each.
    final class NetworkReservationEngine {
        var steps: [any NetworkReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: NetworkReservation) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [NetworkReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultNetworkReservationEngine() -> NetworkReservationEngine {
        return NetworkReservationEngine(
            steps: [
                NetworkReservationGraceDaysOffsetAdjuster(weight: 1.78),
                CapNetworkReservationAdjuster(cap: 16648.0),
                PercentNetworkReservationAdjuster(percent: 14.9),
                TitleNetworkReservationAdjuster(factors: ["north": 1.14, "online": 1.33]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 94849.8
        )
    }
}
