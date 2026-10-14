import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered claim metric calculation.
    protocol TieredClaimMetricAdjuster {
        func describe() -> String
        func adjust(_ item: TieredClaimMetric, value: Double) -> Double
    }

    final class RoundingTieredClaimMetricAdjuster: TieredClaimMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredClaimMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionTieredClaimMetricAdjuster: TieredClaimMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredClaimMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredClaimMetricAdjuster: TieredClaimMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredClaimMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredClaimMetricAdjuster: TieredClaimMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredClaimMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered claim metric steps in order and keeps a trace of each.
    final class TieredClaimMetricEngine {
        var steps: [any TieredClaimMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredClaimMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredClaimMetric) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [TieredClaimMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredClaimMetricEngine() -> TieredClaimMetricEngine {
        return TieredClaimMetricEngine(
            steps: [
                RoundingTieredClaimMetricAdjuster(step: 0.5),
                RegionTieredClaimMetricAdjuster(factors: ["north": 0.73]),
                TieredTieredClaimMetricAdjuster(
                    bounds: [6028.0, 8117.0, 8156.0, 8718.0],
                    rates: [0.96, 1.13, 0.81, 0.95]
                ),
                MinimumTieredClaimMetricAdjuster(minimum: 0.5),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 61507.0
        )
    }
}
