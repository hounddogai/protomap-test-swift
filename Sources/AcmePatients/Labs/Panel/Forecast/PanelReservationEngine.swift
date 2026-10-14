import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel reservation calculation.
    protocol PanelReservationModifier {
        func describe() -> String
        func adjust(_ item: PanelReservation, value: Double) -> Double
    }

    final class CapPanelReservationAdjuster: PanelReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PanelReservationDosageMgOffsetAdjuster: PanelReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: PanelReservation, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class UnitPanelReservationAdjuster: PanelReservationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PanelReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPanelReservationAdjuster: PanelReservationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPanelReservationAdjuster: PanelReservationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPanelReservationAdjuster: PanelReservationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the panel reservation steps in order and keeps a trace of each.
    final class PanelReservationEngine {
        var steps: [any PanelReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelReservation) -> Double {
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

        func evaluateAll(_ items: [PanelReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelReservationEngine() -> PanelReservationEngine {
        return PanelReservationEngine(
            steps: [
                CapPanelReservationAdjuster(cap: 32166.0),
                PanelReservationDosageMgOffsetAdjuster(weight: 1.04),
                UnitPanelReservationAdjuster(factors: ["east": 1.1, "north": 1.24, "west": 1.19]),
                MinimumPanelReservationAdjuster(minimum: 11.0),
                TieredPanelReservationAdjuster(
                    bounds: [2410.0, 4125.0, 5065.0, 6900.0],
                    rates: [0.98, 1.2, 0.95, 0.94]
                ),
                RoundingPanelReservationAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 69097.4
        )
    }
}
