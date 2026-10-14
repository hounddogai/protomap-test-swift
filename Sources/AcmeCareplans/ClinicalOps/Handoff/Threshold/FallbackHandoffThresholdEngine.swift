import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback handoff threshold calculation.
    protocol FallbackHandoffThresholdModifier {
        func describe() -> String
        func adjust(_ item: FallbackHandoffThreshold, value: Double) -> Double
    }

    final class FallbackHandoffThresholdDurationMinutesOffsetAdjuster: FallbackHandoffThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: FallbackHandoffThreshold, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class LocaleFallbackHandoffThresholdAdjuster: FallbackHandoffThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: FallbackHandoffThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackHandoffThresholdAdjuster: FallbackHandoffThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackHandoffThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback handoff threshold steps in order and keeps a trace of each.
    final class FallbackHandoffThresholdEngine {
        var steps: [any FallbackHandoffThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackHandoffThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackHandoffThreshold) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [FallbackHandoffThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackHandoffThresholdEngine() -> FallbackHandoffThresholdEngine {
        return FallbackHandoffThresholdEngine(
            steps: [
                FallbackHandoffThresholdDurationMinutesOffsetAdjuster(weight: 0.79),
                LocaleFallbackHandoffThresholdAdjuster(factors: ["west": 1.21]),
                TieredFallbackHandoffThresholdAdjuster(bounds: [1714.0, 7923.0], rates: [0.8, 1.03]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 90983.0
        )
    }
}
