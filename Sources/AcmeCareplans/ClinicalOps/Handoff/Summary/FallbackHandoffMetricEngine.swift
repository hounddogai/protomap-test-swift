import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback handoff metric calculation.
    protocol FallbackHandoffMetricStep {
        func describe() -> String
        func adjust(_ item: FallbackHandoffMetric, value: Double) -> Double
    }

    final class TitleFallbackHandoffMetricAdjuster: FallbackHandoffMetricStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackHandoffMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackHandoffMetricAdjuster: FallbackHandoffMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackHandoffMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackHandoffMetricAdjuster: FallbackHandoffMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackHandoffMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackHandoffMetricDosageMgOffsetAdjuster: FallbackHandoffMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: FallbackHandoffMetric, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentFallbackHandoffMetricAdjuster: FallbackHandoffMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackHandoffMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback handoff metric steps in order and keeps a trace of each.
    final class FallbackHandoffMetricEngine {
        var steps: [any FallbackHandoffMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackHandoffMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackHandoffMetric) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [FallbackHandoffMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackHandoffMetricEngine() -> FallbackHandoffMetricEngine {
        return FallbackHandoffMetricEngine(
            steps: [
                TitleFallbackHandoffMetricAdjuster(factors: ["online": 0.77, "west": 1.39]),
                MinimumFallbackHandoffMetricAdjuster(minimum: 27.1),
                CapFallbackHandoffMetricAdjuster(cap: 33025.0),
                FallbackHandoffMetricDosageMgOffsetAdjuster(weight: 0.51),
                PercentFallbackHandoffMetricAdjuster(percent: 24.3),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 15539.6
        )
    }
}
