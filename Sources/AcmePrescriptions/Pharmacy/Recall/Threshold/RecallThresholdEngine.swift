import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall threshold calculation.
    protocol RecallThresholdModifier {
        func describe() -> String
        func adjust(_ item: RecallThreshold, value: Double) -> Double
    }

    final class TieredRecallThresholdAdjuster: RecallThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRecallThresholdAdjuster: RecallThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRecallThresholdAdjuster: RecallThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityRecallThresholdAdjuster: RecallThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RecallThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RecallThresholdMaximumOffsetAdjuster: RecallThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RecallThreshold, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the recall threshold steps in order and keeps a trace of each.
    final class RecallThresholdEngine {
        var steps: [any RecallThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallThreshold) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [RecallThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallThresholdEngine() -> RecallThresholdEngine {
        return RecallThresholdEngine(
            steps: [
                TieredRecallThresholdAdjuster(bounds: [2385.0, 8432.0], rates: [0.81, 1.06]),
                CapRecallThresholdAdjuster(cap: 44327.0),
                RoundingRecallThresholdAdjuster(step: 0.1),
                FacilityRecallThresholdAdjuster(factors: ["online": 0.94]),
                RecallThresholdMaximumOffsetAdjuster(weight: 1.36),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 43372.8
        )
    }
}
