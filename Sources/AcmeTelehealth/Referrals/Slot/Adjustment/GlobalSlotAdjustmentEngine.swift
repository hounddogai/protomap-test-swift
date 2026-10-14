import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global slot adjustment calculation.
    protocol GlobalSlotAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: GlobalSlotAdjustment, value: Double) -> Double
    }

    final class TieredGlobalSlotAdjustmentAdjuster: GlobalSlotAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalSlotAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalSlotAdjustmentAdjuster: GlobalSlotAdjustmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSlotAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalSlotAdjustmentAdjuster: GlobalSlotAdjustmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalSlotAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global slot adjustment steps in order and keeps a trace of each.
    final class GlobalSlotAdjustmentEngine {
        var steps: [any GlobalSlotAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSlotAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalSlotAdjustment) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [GlobalSlotAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalSlotAdjustmentEngine() -> GlobalSlotAdjustmentEngine {
        return GlobalSlotAdjustmentEngine(
            steps: [
                TieredGlobalSlotAdjustmentAdjuster(
                    bounds: [2346.0, 4514.0, 5221.0, 6303.0],
                    rates: [1.15, 1.12, 1.14, 0.98]
                ),
                MinimumGlobalSlotAdjustmentAdjuster(minimum: 32.8),
                PercentGlobalSlotAdjustmentAdjuster(percent: -14.6),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 41783.2
        )
    }
}
