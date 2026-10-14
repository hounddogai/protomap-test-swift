import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global inventory threshold calculation.
    protocol GlobalInventoryThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalInventoryThreshold, value: Double) -> Double
    }

    final class MinimumGlobalInventoryThresholdAdjuster: GlobalInventoryThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalInventoryThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalInventoryThresholdAdjuster: GlobalInventoryThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalInventoryThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalInventoryThresholdAdjuster: GlobalInventoryThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInventoryThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalInventoryThresholdGraceDaysOffsetAdjuster: GlobalInventoryThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: GlobalInventoryThreshold, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the global inventory threshold steps in order and keeps a trace of each.
    final class GlobalInventoryThresholdEngine {
        var steps: [any GlobalInventoryThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInventoryThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalInventoryThreshold) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [GlobalInventoryThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalInventoryThresholdEngine() -> GlobalInventoryThresholdEngine {
        return GlobalInventoryThresholdEngine(
            steps: [
                MinimumGlobalInventoryThresholdAdjuster(minimum: 17.0),
                PercentGlobalInventoryThresholdAdjuster(percent: -11.3),
                TieredGlobalInventoryThresholdAdjuster(bounds: [2137.0, 6352.0], rates: [1.05, 1.0]),
                GlobalInventoryThresholdGraceDaysOffsetAdjuster(weight: 0.02),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 97740.2
        )
    }
}
