import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict closure reservation calculation.
    protocol StrictClosureReservationModifier {
        func describe() -> String
        func adjust(_ item: StrictClosureReservation, value: Double) -> Double
    }

    final class StrictClosureReservationFloorValueOffsetAdjuster: StrictClosureReservationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: StrictClosureReservation, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CapStrictClosureReservationAdjuster: StrictClosureReservationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictClosureReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictClosureReservationAdjuster: StrictClosureReservationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictClosureReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict closure reservation steps in order and keeps a trace of each.
    final class StrictClosureReservationEngine {
        var steps: [any StrictClosureReservationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictClosureReservationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictClosureReservation) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [StrictClosureReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictClosureReservationEngine() -> StrictClosureReservationEngine {
        return StrictClosureReservationEngine(
            steps: [
                StrictClosureReservationFloorValueOffsetAdjuster(weight: 0.2),
                CapStrictClosureReservationAdjuster(cap: 14695.0),
                PercentStrictClosureReservationAdjuster(percent: -3.3),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 75902.5
        )
    }
}
