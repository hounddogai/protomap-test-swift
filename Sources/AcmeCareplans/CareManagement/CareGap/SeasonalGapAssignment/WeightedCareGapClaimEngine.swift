import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted care gap claim calculation.
    protocol WeightedCareGapClaimStep {
        func describe() -> String
        func adjust(_ item: WeightedCareGapClaim, value: Double) -> Double
    }

    final class RegionWeightedCareGapClaimAdjuster: WeightedCareGapClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedCareGapClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWeightedCareGapClaimAdjuster: WeightedCareGapClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedCareGapClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedCareGapClaimAdjuster: WeightedCareGapClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedCareGapClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted care gap claim steps in order and keeps a trace of each.
    final class WeightedCareGapClaimEngine {
        var steps: [any WeightedCareGapClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCareGapClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedCareGapClaim) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [WeightedCareGapClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedCareGapClaimEngine() -> WeightedCareGapClaimEngine {
        return WeightedCareGapClaimEngine(
            steps: [
                RegionWeightedCareGapClaimAdjuster(factors: ["south": 0.99]),
                RoundingWeightedCareGapClaimAdjuster(step: 5.0),
                PercentWeightedCareGapClaimAdjuster(percent: 8.6),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 12616.3
        )
    }
}
