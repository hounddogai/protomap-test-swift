import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall reservation calculation.
    protocol RecallReservationStep {
        func describe() -> String
        func adjust(_ item: RecallReservation, value: Double) -> Double
    }

    final class TieredRecallReservationAdjuster: RecallReservationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRecallReservationAdjuster: RecallReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRecallReservationAdjuster: RecallReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionRecallReservationAdjuster: RecallReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RecallReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRecallReservationAdjuster: RecallReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRecallReservationAdjuster: RecallReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the recall reservation steps in order and keeps a trace of each.
    final class RecallReservationEngine {
        var steps: [any RecallReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallReservation) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [RecallReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallReservationEngine() -> RecallReservationEngine {
        return RecallReservationEngine(
            steps: [
                TieredRecallReservationAdjuster(bounds: [3136.0, 3932.0, 6762.0], rates: [1.05, 0.9, 0.88]),
                PercentRecallReservationAdjuster(percent: 14.9),
                RoundingRecallReservationAdjuster(step: 1.0),
                RegionRecallReservationAdjuster(factors: ["online": 0.95, "west": 1.06, "central": 0.76]),
                MinimumRecallReservationAdjuster(minimum: 12.6),
                CapRecallReservationAdjuster(cap: 7801.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 44375.9
        )
    }
}
