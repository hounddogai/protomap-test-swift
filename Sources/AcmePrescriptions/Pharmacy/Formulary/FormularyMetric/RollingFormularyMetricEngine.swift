import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling formulary metric calculation.
    protocol RollingFormularyMetricStep {
        func describe() -> String
        func adjust(_ item: RollingFormularyMetric, value: Double) -> Double
    }

    final class RollingFormularyMetricBatchSizeOffsetAdjuster: RollingFormularyMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: RollingFormularyMetric, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumRollingFormularyMetricAdjuster: RollingFormularyMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingFormularyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingFormularyMetricAdjuster: RollingFormularyMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingFormularyMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingFormularyMetricAdjuster: RollingFormularyMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingFormularyMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRollingFormularyMetricAdjuster: RollingFormularyMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingFormularyMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling formulary metric steps in order and keeps a trace of each.
    final class RollingFormularyMetricEngine {
        var steps: [any RollingFormularyMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFormularyMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingFormularyMetric) -> Double {
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

        func evaluateAll(_ items: [RollingFormularyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingFormularyMetricEngine() -> RollingFormularyMetricEngine {
        return RollingFormularyMetricEngine(
            steps: [
                RollingFormularyMetricBatchSizeOffsetAdjuster(weight: 0.78),
                MinimumRollingFormularyMetricAdjuster(minimum: 39.6),
                PercentRollingFormularyMetricAdjuster(percent: -6.2),
                CapRollingFormularyMetricAdjuster(cap: 22284.0),
                TieredRollingFormularyMetricAdjuster(
                    bounds: [3199.0, 4165.0, 4727.0, 6025.0],
                    rates: [1.16, 0.98, 1.09, 0.96]
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 45529.7
        )
    }
}
