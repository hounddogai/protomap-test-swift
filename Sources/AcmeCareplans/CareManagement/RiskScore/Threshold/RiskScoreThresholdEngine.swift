import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score threshold calculation.
    protocol RiskScoreThresholdModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double
    }

    final class TieredRiskScoreThresholdAdjuster: RiskScoreThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRiskScoreThresholdAdjuster: RiskScoreThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRiskScoreThresholdAdjuster: RiskScoreThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRiskScoreThresholdAdjuster: RiskScoreThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RiskScoreThresholdQuantityOffsetAdjuster: RiskScoreThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapRiskScoreThresholdAdjuster: RiskScoreThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the risk score threshold steps in order and keeps a trace of each.
    final class RiskScoreThresholdEngine {
        var steps: [any RiskScoreThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreThreshold) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RiskScoreThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreThresholdEngine() -> RiskScoreThresholdEngine {
        return RiskScoreThresholdEngine(
            steps: [
                TieredRiskScoreThresholdAdjuster(
                    bounds: [1262.0, 2462.0, 4582.0, 8376.0],
                    rates: [0.82, 1.1, 0.9, 0.84]
                ),
                MinimumRiskScoreThresholdAdjuster(minimum: 37.2),
                PercentRiskScoreThresholdAdjuster(percent: 22.4),
                NameRiskScoreThresholdAdjuster(factors: ["online": 0.98, "south": 1.19]),
                RiskScoreThresholdQuantityOffsetAdjuster(weight: 1.27),
                CapRiskScoreThresholdAdjuster(cap: 11211.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 5118.7
        )
    }
}
