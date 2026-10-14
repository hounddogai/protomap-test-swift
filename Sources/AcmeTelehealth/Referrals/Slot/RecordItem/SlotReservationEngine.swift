import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot reservation calculation.
    protocol SlotReservationFactor {
        func describe() -> String
        func adjust(_ item: SlotReservation, value: Double) -> Double
    }

    final class MinimumSlotReservationAdjuster: SlotReservationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSlotReservationAdjuster: SlotReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SlotReservationWindowDaysOffsetAdjuster: SlotReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SlotReservation, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapSlotReservationAdjuster: SlotReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the slot reservation steps in order and keeps a trace of each.
    final class SlotReservationEngine {
        var steps: [any SlotReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotReservation) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [SlotReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotReservationEngine() -> SlotReservationEngine {
        return SlotReservationEngine(
            steps: [
                MinimumSlotReservationAdjuster(minimum: 36.9),
                TieredSlotReservationAdjuster(bounds: [420.0, 2811.0, 4508.0, 8811.0], rates: [1.0, 0.97, 0.92, 1.15]),
                SlotReservationWindowDaysOffsetAdjuster(weight: 0.93),
                CapSlotReservationAdjuster(cap: 43336.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 39150.6
        )
    }
}
