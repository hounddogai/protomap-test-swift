import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted credential variance calculation.
    protocol WeightedCredentialVarianceModifier {
        func describe() -> String
        func adjust(_ item: WeightedCredentialVariance, value: Double) -> Double
    }

    final class LabelWeightedCredentialVarianceAdjuster: WeightedCredentialVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedCredentialVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedCredentialVarianceAdjuster: WeightedCredentialVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedCredentialVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedCredentialVarianceAdjuster: WeightedCredentialVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedCredentialVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedCredentialVarianceAdjuster: WeightedCredentialVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedCredentialVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedCredentialVarianceFloorValueOffsetAdjuster: WeightedCredentialVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: WeightedCredentialVariance, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the weighted credential variance steps in order and keeps a trace of each.
    final class WeightedCredentialVarianceEngine {
        var steps: [any WeightedCredentialVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCredentialVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedCredentialVariance) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [WeightedCredentialVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedCredentialVarianceEngine() -> WeightedCredentialVarianceEngine {
        return WeightedCredentialVarianceEngine(
            steps: [
                LabelWeightedCredentialVarianceAdjuster(factors: ["retail": 0.86]),
                PercentWeightedCredentialVarianceAdjuster(percent: -12.7),
                CapWeightedCredentialVarianceAdjuster(cap: 8102.0),
                RoundingWeightedCredentialVarianceAdjuster(step: 0.5),
                WeightedCredentialVarianceFloorValueOffsetAdjuster(weight: 0.47),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 33669.1
        )
    }
}
