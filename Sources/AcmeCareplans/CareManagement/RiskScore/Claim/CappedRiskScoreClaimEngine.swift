import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped risk score claim calculation.
    protocol CappedRiskScoreClaimModifier {
        func describe() -> String
        func adjust(_ item: CappedRiskScoreClaim, value: Double) -> Double
    }

    final class RoundingCappedRiskScoreClaimAdjuster: CappedRiskScoreClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedRiskScoreClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryCappedRiskScoreClaimAdjuster: CappedRiskScoreClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CappedRiskScoreClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedRiskScoreClaimAdjuster: CappedRiskScoreClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedRiskScoreClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped risk score claim steps in order and keeps a trace of each.
    final class CappedRiskScoreClaimEngine {
        var steps: [any CappedRiskScoreClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRiskScoreClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedRiskScoreClaim) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedRiskScoreClaimModifier = steps[index]
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

        func evaluateAll(_ items: [CappedRiskScoreClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedRiskScoreClaimEngine() -> CappedRiskScoreClaimEngine {
        return CappedRiskScoreClaimEngine(
            steps: [
                RoundingCappedRiskScoreClaimAdjuster(step: 1.0),
                CategoryCappedRiskScoreClaimAdjuster(factors: ["north": 1.33]),
                TieredCappedRiskScoreClaimAdjuster(bounds: [814.0, 3421.0, 4575.0], rates: [1.06, 0.87, 1.09]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 40929.8
        )
    }
}
