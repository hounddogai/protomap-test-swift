import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness reservation calculation.
    protocol WitnessReservationStep {
        func describe() -> String
        func adjust(_ item: WitnessReservation, value: Double) -> Double
    }

    final class LabelWitnessReservationAdjuster: WitnessReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WitnessReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWitnessReservationAdjuster: WitnessReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WitnessReservationPriorityOffsetAdjuster: WitnessReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: WitnessReservation, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class CapWitnessReservationAdjuster: WitnessReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the witness reservation steps in order and keeps a trace of each.
    final class WitnessReservationEngine {
        var steps: [any WitnessReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessReservation) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessReservationStep = steps[index]
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

        func evaluateAll(_ items: [WitnessReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessReservationEngine() -> WitnessReservationEngine {
        return WitnessReservationEngine(
            steps: [
                LabelWitnessReservationAdjuster(factors: ["retail": 1.3, "west": 1.29]),
                TieredWitnessReservationAdjuster(bounds: [1474.0, 6639.0, 6858.0], rates: [0.96, 0.96, 1.15]),
                WitnessReservationPriorityOffsetAdjuster(weight: 0.17),
                CapWitnessReservationAdjuster(cap: 26485.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 90453.6
        )
    }
}
