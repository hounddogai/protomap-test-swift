import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary read reservation calculation.
    protocol PrimaryReadReservationFactor {
        func describe() -> String
        func adjust(_ item: PrimaryReadReservation, value: Double) -> Double
    }

    final class PrimaryReadReservationUpdatedAtOffsetAdjuster: PrimaryReadReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: PrimaryReadReservation, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentPrimaryReadReservationAdjuster: PrimaryReadReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryReadReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryReadReservationAdjuster: PrimaryReadReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryReadReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryReadReservationAdjuster: PrimaryReadReservationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryReadReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary read reservation steps in order and keeps a trace of each.
    final class PrimaryReadReservationEngine {
        var steps: [any PrimaryReadReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryReadReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryReadReservation) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [PrimaryReadReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryReadReservationEngine() -> PrimaryReadReservationEngine {
        return PrimaryReadReservationEngine(
            steps: [
                PrimaryReadReservationUpdatedAtOffsetAdjuster(weight: 1.7),
                PercentPrimaryReadReservationAdjuster(percent: 12.2),
                CapPrimaryReadReservationAdjuster(cap: 13172.0),
                MinimumPrimaryReadReservationAdjuster(minimum: 7.3),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 75851.4
        )
    }
}
