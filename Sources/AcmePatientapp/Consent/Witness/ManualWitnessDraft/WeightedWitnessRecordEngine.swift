import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted witness record calculation.
    protocol WeightedWitnessRecordModifier {
        func describe() -> String
        func adjust(_ item: WeightedWitnessRecord, value: Double) -> Double
    }

    final class RoundingWeightedWitnessRecordAdjuster: WeightedWitnessRecordModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedWitnessRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityWeightedWitnessRecordAdjuster: WeightedWitnessRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: WeightedWitnessRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedWitnessRecordAdjuster: WeightedWitnessRecordModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedWitnessRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted witness record steps in order and keeps a trace of each.
    final class WeightedWitnessRecordEngine {
        var steps: [any WeightedWitnessRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedWitnessRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedWitnessRecord) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [WeightedWitnessRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedWitnessRecordEngine() -> WeightedWitnessRecordEngine {
        return WeightedWitnessRecordEngine(
            steps: [
                RoundingWeightedWitnessRecordAdjuster(step: 1.0),
                FacilityWeightedWitnessRecordAdjuster(factors: ["retail": 0.88]),
                PercentWeightedWitnessRecordAdjuster(percent: -9.2),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 35947.8
        )
    }
}
