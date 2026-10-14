import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled care gap variance calculation.
    protocol ScheduledCareGapVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledCareGapVariance, value: Double) -> Double
    }

    final class TieredScheduledCareGapVarianceAdjuster: ScheduledCareGapVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareGapVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentScheduledCareGapVarianceAdjuster: ScheduledCareGapVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCareGapVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledCareGapVarianceDosageMgOffsetAdjuster: ScheduledCareGapVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ScheduledCareGapVariance, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the scheduled care gap variance steps in order and keeps a trace of each.
    final class ScheduledCareGapVarianceEngine {
        var steps: [any ScheduledCareGapVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareGapVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledCareGapVariance) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ScheduledCareGapVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledCareGapVarianceEngine() -> ScheduledCareGapVarianceEngine {
        return ScheduledCareGapVarianceEngine(
            steps: [
                TieredScheduledCareGapVarianceAdjuster(bounds: [446.0, 4246.0], rates: [1.16, 1.08]),
                PercentScheduledCareGapVarianceAdjuster(percent: -7.2),
                ScheduledCareGapVarianceDosageMgOffsetAdjuster(weight: 1.96),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 7893.1
        )
    }
}
