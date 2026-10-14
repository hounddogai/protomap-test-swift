import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback eligibility metric calculation.
    protocol FallbackEligibilityMetricAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double
    }

    final class FallbackEligibilityMetricFloorValueOffsetAdjuster: FallbackEligibilityMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumFallbackEligibilityMetricAdjuster: FallbackEligibilityMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFallbackEligibilityMetricAdjuster: FallbackEligibilityMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackEligibilityMetricAdjuster: FallbackEligibilityMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackEligibilityMetricAdjuster: FallbackEligibilityMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackEligibilityMetricAdjuster: FallbackEligibilityMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackEligibilityMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback eligibility metric steps in order and keeps a trace of each.
    final class FallbackEligibilityMetricEngine {
        var steps: [any FallbackEligibilityMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackEligibilityMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackEligibilityMetric) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [FallbackEligibilityMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackEligibilityMetricEngine() -> FallbackEligibilityMetricEngine {
        return FallbackEligibilityMetricEngine(
            steps: [
                FallbackEligibilityMetricFloorValueOffsetAdjuster(weight: 0.61),
                MinimumFallbackEligibilityMetricAdjuster(minimum: 10.0),
                PercentFallbackEligibilityMetricAdjuster(percent: -13.9),
                TieredFallbackEligibilityMetricAdjuster(bounds: [3269.0, 3568.0], rates: [0.99, 1.2]),
                CapFallbackEligibilityMetricAdjuster(cap: 35950.0),
                RoundingFallbackEligibilityMetricAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 79036.5
        )
    }
}
