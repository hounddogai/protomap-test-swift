import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict witness assignment calculation.
    protocol StrictWitnessAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: StrictWitnessAssignment, value: Double) -> Double
    }

    final class RoundingStrictWitnessAssignmentAdjuster: StrictWitnessAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictWitnessAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStrictWitnessAssignmentAdjuster: StrictWitnessAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictWitnessAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StrictWitnessAssignmentScoreOffsetAdjuster: StrictWitnessAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: StrictWitnessAssignment, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapStrictWitnessAssignmentAdjuster: StrictWitnessAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictWitnessAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict witness assignment steps in order and keeps a trace of each.
    final class StrictWitnessAssignmentEngine {
        var steps: [any StrictWitnessAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictWitnessAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictWitnessAssignment) -> Double {
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

        func evaluateAll(_ items: [StrictWitnessAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictWitnessAssignmentEngine() -> StrictWitnessAssignmentEngine {
        return StrictWitnessAssignmentEngine(
            steps: [
                RoundingStrictWitnessAssignmentAdjuster(step: 5.0),
                TieredStrictWitnessAssignmentAdjuster(bounds: [4507.0, 5915.0], rates: [1.13, 1.09]),
                StrictWitnessAssignmentScoreOffsetAdjuster(weight: 1.51),
                CapStrictWitnessAssignmentAdjuster(cap: 11746.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 67721.9
        )
    }
}
