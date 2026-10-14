import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional result reservation calculation.
    protocol RegionalResultReservationStep {
        func describe() -> String
        func adjust(_ item: RegionalResultReservation, value: Double) -> Double
    }

    final class RegionalResultReservationAcuityOffsetAdjuster: RegionalResultReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RegionalResultReservation, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class RoundingRegionalResultReservationAdjuster: RegionalResultReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalResultReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalResultReservationAdjuster: RegionalResultReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalResultReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRegionalResultReservationAdjuster: RegionalResultReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalResultReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional result reservation steps in order and keeps a trace of each.
    final class RegionalResultReservationEngine {
        var steps: [any RegionalResultReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalResultReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalResultReservation) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [RegionalResultReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalResultReservationEngine() -> RegionalResultReservationEngine {
        return RegionalResultReservationEngine(
            steps: [
                RegionalResultReservationAcuityOffsetAdjuster(weight: 0.15),
                RoundingRegionalResultReservationAdjuster(step: 0.05),
                CapRegionalResultReservationAdjuster(cap: 48659.0),
                MinimumRegionalResultReservationAdjuster(minimum: 19.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 48816.8
        )
    }
}
