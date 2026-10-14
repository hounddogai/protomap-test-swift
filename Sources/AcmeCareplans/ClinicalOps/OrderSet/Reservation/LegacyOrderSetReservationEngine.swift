import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy order set reservation calculation.
    protocol LegacyOrderSetReservationFactor {
        func describe() -> String
        func adjust(_ item: LegacyOrderSetReservation, value: Double) -> Double
    }

    final class LegacyOrderSetReservationQuantityOffsetAdjuster: LegacyOrderSetReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LegacyOrderSetReservation, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapLegacyOrderSetReservationAdjuster: LegacyOrderSetReservationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyOrderSetReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLegacyOrderSetReservationAdjuster: LegacyOrderSetReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyOrderSetReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyOrderSetReservationAdjuster: LegacyOrderSetReservationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyOrderSetReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLegacyOrderSetReservationAdjuster: LegacyOrderSetReservationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyOrderSetReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy order set reservation steps in order and keeps a trace of each.
    final class LegacyOrderSetReservationEngine {
        var steps: [any LegacyOrderSetReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyOrderSetReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyOrderSetReservation) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [LegacyOrderSetReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyOrderSetReservationEngine() -> LegacyOrderSetReservationEngine {
        return LegacyOrderSetReservationEngine(
            steps: [
                LegacyOrderSetReservationQuantityOffsetAdjuster(weight: 1.91),
                CapLegacyOrderSetReservationAdjuster(cap: 29662.0),
                PercentLegacyOrderSetReservationAdjuster(percent: -24.8),
                RoundingLegacyOrderSetReservationAdjuster(step: 0.25),
                MinimumLegacyOrderSetReservationAdjuster(minimum: 16.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 37953.9
        )
    }
}
