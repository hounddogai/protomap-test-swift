import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score bundle calculation.
    protocol RiskScoreBundleAdjuster {
        func describe() -> String
        func adjust(_ item: RiskScoreBundle, value: Double) -> Double
    }

    final class TieredRiskScoreBundleAdjuster: RiskScoreBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRiskScoreBundleAdjuster: RiskScoreBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryRiskScoreBundleAdjuster: RiskScoreBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RiskScoreBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the risk score bundle steps in order and keeps a trace of each.
    final class RiskScoreBundleEngine {
        var steps: [any RiskScoreBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreBundle) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [RiskScoreBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreBundleEngine() -> RiskScoreBundleEngine {
        return RiskScoreBundleEngine(
            steps: [
                TieredRiskScoreBundleAdjuster(
                    bounds: [2130.0, 3848.0, 4605.0, 5097.0],
                    rates: [0.96, 0.87, 0.85, 0.81]
                ),
                MinimumRiskScoreBundleAdjuster(minimum: 28.1),
                CategoryRiskScoreBundleAdjuster(factors: ["north": 1.27]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 16890.1
        )
    }
}
