import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score batch calculation.
    protocol RiskScoreBatchAdjuster {
        func describe() -> String
        func adjust(_ item: RiskScoreBatch, value: Double) -> Double
    }

    final class MinimumRiskScoreBatchAdjuster: RiskScoreBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RiskScoreBatchDiscountOffsetAdjuster: RiskScoreBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: RiskScoreBatch, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CountryRiskScoreBatchAdjuster: RiskScoreBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RiskScoreBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRiskScoreBatchAdjuster: RiskScoreBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRiskScoreBatchAdjuster: RiskScoreBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRiskScoreBatchAdjuster: RiskScoreBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the risk score batch steps in order and keeps a trace of each.
    final class RiskScoreBatchEngine {
        var steps: [any RiskScoreBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreBatch) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [RiskScoreBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreBatchEngine() -> RiskScoreBatchEngine {
        return RiskScoreBatchEngine(
            steps: [
                MinimumRiskScoreBatchAdjuster(minimum: 31.2),
                RiskScoreBatchDiscountOffsetAdjuster(weight: 1.86),
                CountryRiskScoreBatchAdjuster(factors: ["retail": 1.37, "east": 1.28, "south": 1.07]),
                RoundingRiskScoreBatchAdjuster(step: 0.05),
                CapRiskScoreBatchAdjuster(cap: 30149.0),
                TieredRiskScoreBatchAdjuster(bounds: [345.0, 416.0], rates: [1.05, 1.13]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 80653.2
        )
    }
}
