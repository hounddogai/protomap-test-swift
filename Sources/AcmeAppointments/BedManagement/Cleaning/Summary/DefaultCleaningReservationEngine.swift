import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default cleaning reservation calculation.
    protocol DefaultCleaningReservationAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultCleaningReservation, value: Double) -> Double
    }

    final class PercentDefaultCleaningReservationAdjuster: DefaultCleaningReservationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCleaningReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultCleaningReservationAdjuster: DefaultCleaningReservationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCleaningReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelDefaultCleaningReservationAdjuster: DefaultCleaningReservationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: DefaultCleaningReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default cleaning reservation steps in order and keeps a trace of each.
    final class DefaultCleaningReservationEngine {
        var steps: [any DefaultCleaningReservationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCleaningReservationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCleaningReservation) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [DefaultCleaningReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCleaningReservationEngine() -> DefaultCleaningReservationEngine {
        return DefaultCleaningReservationEngine(
            steps: [
                PercentDefaultCleaningReservationAdjuster(percent: 14.5),
                MinimumDefaultCleaningReservationAdjuster(minimum: 35.4),
                ChannelDefaultCleaningReservationAdjuster(factors: ["central": 1.17]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 75263.5
        )
    }
}
