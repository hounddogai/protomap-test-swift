import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback float pool schedule calculation.
    protocol FallbackFloatPoolScheduleStep {
        func describe() -> String
        func adjust(_ item: FallbackFloatPoolSchedule, value: Double) -> Double
    }

    final class RoundingFallbackFloatPoolScheduleAdjuster: FallbackFloatPoolScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackFloatPoolSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackFloatPoolScheduleAdjuster: FallbackFloatPoolScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackFloatPoolSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackFloatPoolScheduleThresholdOffsetAdjuster: FallbackFloatPoolScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: FallbackFloatPoolSchedule, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class PercentFallbackFloatPoolScheduleAdjuster: FallbackFloatPoolScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackFloatPoolSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback float pool schedule steps in order and keeps a trace of each.
    final class FallbackFloatPoolScheduleEngine {
        var steps: [any FallbackFloatPoolScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFloatPoolScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackFloatPoolSchedule) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [FallbackFloatPoolSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackFloatPoolScheduleEngine() -> FallbackFloatPoolScheduleEngine {
        return FallbackFloatPoolScheduleEngine(
            steps: [
                RoundingFallbackFloatPoolScheduleAdjuster(step: 0.05),
                TieredFallbackFloatPoolScheduleAdjuster(bounds: [3504.0, 6451.0], rates: [1.18, 0.9]),
                FallbackFloatPoolScheduleThresholdOffsetAdjuster(weight: 0.08),
                PercentFallbackFloatPoolScheduleAdjuster(percent: 24.9),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 12925.0
        )
    }
}
