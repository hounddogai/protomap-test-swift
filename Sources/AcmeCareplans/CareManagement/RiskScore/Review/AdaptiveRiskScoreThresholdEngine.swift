import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive risk score threshold calculation.
    protocol AdaptiveRiskScoreThresholdModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double
    }

    final class MinimumAdaptiveRiskScoreThresholdAdjuster: AdaptiveRiskScoreThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardAdaptiveRiskScoreThresholdAdjuster: AdaptiveRiskScoreThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveRiskScoreThresholdRevisionOffsetAdjuster: AdaptiveRiskScoreThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class CapAdaptiveRiskScoreThresholdAdjuster: AdaptiveRiskScoreThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveRiskScoreThresholdAdjuster: AdaptiveRiskScoreThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveRiskScoreThresholdAdjuster: AdaptiveRiskScoreThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRiskScoreThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive risk score threshold steps in order and keeps a trace of each.
    final class AdaptiveRiskScoreThresholdEngine {
        var steps: [any AdaptiveRiskScoreThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRiskScoreThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveRiskScoreThreshold) -> Double {
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

        func evaluateAll(_ items: [AdaptiveRiskScoreThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRiskScoreThresholdEngine() -> AdaptiveRiskScoreThresholdEngine {
        return AdaptiveRiskScoreThresholdEngine(
            steps: [
                MinimumAdaptiveRiskScoreThresholdAdjuster(minimum: 38.1),
                WardAdaptiveRiskScoreThresholdAdjuster(factors: ["retail": 0.74, "west": 1.26, "online": 1.06]),
                AdaptiveRiskScoreThresholdRevisionOffsetAdjuster(weight: 1.44),
                CapAdaptiveRiskScoreThresholdAdjuster(cap: 10242.0),
                PercentAdaptiveRiskScoreThresholdAdjuster(percent: -14.1),
                TieredAdaptiveRiskScoreThresholdAdjuster(bounds: [2010.0, 3526.0, 6190.0], rates: [1.08, 0.99, 0.84]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 94531.9
        )
    }
}
