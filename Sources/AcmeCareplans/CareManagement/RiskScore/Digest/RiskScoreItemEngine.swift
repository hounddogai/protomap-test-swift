import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score item calculation.
    protocol RiskScoreItemModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreItem, value: Double) -> Double
    }

    final class TieredRiskScoreItemAdjuster: RiskScoreItemModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreItem, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRiskScoreItemAdjuster: RiskScoreItemModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreItem, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRiskScoreItemAdjuster: RiskScoreItemModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreItem, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the risk score item steps in order and keeps a trace of each.
    final class RiskScoreItemEngine {
        var steps: [any RiskScoreItemModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreItemModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreItem) -> Double {
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

        func evaluateAll(_ items: [RiskScoreItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreItemEngine() -> RiskScoreItemEngine {
        return RiskScoreItemEngine(
            steps: [
                TieredRiskScoreItemAdjuster(bounds: [2211.0, 6091.0, 6861.0], rates: [1.04, 0.8, 1.09]),
                CapRiskScoreItemAdjuster(cap: 5998.0),
                MinimumRiskScoreItemAdjuster(minimum: 17.2),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 48840.0
        )
    }
}
