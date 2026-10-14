import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan reservation calculation.
    protocol AcuityPlanReservationStep {
        func describe() -> String
        func adjust(_ item: AcuityPlanReservation, value: Double) -> Double
    }

    final class CapAcuityPlanReservationAdjuster: AcuityPlanReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAcuityPlanReservationAdjuster: AcuityPlanReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAcuityPlanReservationAdjuster: AcuityPlanReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AcuityPlanReservationSequenceOffsetAdjuster: AcuityPlanReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: AcuityPlanReservation, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingAcuityPlanReservationAdjuster: AcuityPlanReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the acuity plan reservation steps in order and keeps a trace of each.
    final class AcuityPlanReservationEngine {
        var steps: [any AcuityPlanReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanReservation) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanReservationStep = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanReservationEngine() -> AcuityPlanReservationEngine {
        return AcuityPlanReservationEngine(
            steps: [
                CapAcuityPlanReservationAdjuster(cap: 41492.0),
                MinimumAcuityPlanReservationAdjuster(minimum: 16.5),
                TieredAcuityPlanReservationAdjuster(
                    bounds: [985.0, 1912.0, 3574.0, 5991.0],
                    rates: [0.82, 0.97, 0.86, 1.04]
                ),
                AcuityPlanReservationSequenceOffsetAdjuster(weight: 1.46),
                RoundingAcuityPlanReservationAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 79886.6
        )
    }
}
