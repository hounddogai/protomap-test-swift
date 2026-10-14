import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy result variance calculation.
    protocol LegacyResultVarianceFactor {
        func describe() -> String
        func adjust(_ item: LegacyResultVariance, value: Double) -> Double
    }

    final class TieredLegacyResultVarianceAdjuster: LegacyResultVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyResultVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LegacyResultVarianceThresholdOffsetAdjuster: LegacyResultVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LegacyResultVariance, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingLegacyResultVarianceAdjuster: LegacyResultVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyResultVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryLegacyResultVarianceAdjuster: LegacyResultVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LegacyResultVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy result variance steps in order and keeps a trace of each.
    final class LegacyResultVarianceEngine {
        var steps: [any LegacyResultVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyResultVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyResultVariance) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [LegacyResultVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyResultVarianceEngine() -> LegacyResultVarianceEngine {
        return LegacyResultVarianceEngine(
            steps: [
                TieredLegacyResultVarianceAdjuster(
                    bounds: [1188.0, 4002.0, 8194.0, 9631.0],
                    rates: [1.09, 0.97, 1.11, 1.11]
                ),
                LegacyResultVarianceThresholdOffsetAdjuster(weight: 1.43),
                RoundingLegacyResultVarianceAdjuster(step: 5.0),
                CategoryLegacyResultVarianceAdjuster(factors: ["west": 0.88, "east": 1.32, "north": 1.22]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 60296.9
        )
    }
}
