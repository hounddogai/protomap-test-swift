import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered task override calculation.
    protocol TaskBudgetTieredTaskOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: TieredTaskOverride, value: Double) -> Double
    }

    final class TieredTaskOverrideUpdatedAtOffsetAdjuster: TaskBudgetTieredTaskOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: TieredTaskOverride, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class LocaleTieredTaskOverrideAdjuster: TaskBudgetTieredTaskOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: TieredTaskOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredTaskOverrideAdjuster: TaskBudgetTieredTaskOverrideAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredTaskOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTieredTaskOverrideAdjuster: TaskBudgetTieredTaskOverrideAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredTaskOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredTaskOverrideAdjuster: TaskBudgetTieredTaskOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredTaskOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered task override steps in order and keeps a trace of each.
    final class TieredTaskOverrideEngine {
        var steps: [any TaskBudgetTieredTaskOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskBudgetTieredTaskOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredTaskOverride) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [TieredTaskOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredTaskOverrideEngine() -> TieredTaskOverrideEngine {
        return TieredTaskOverrideEngine(
            steps: [
                TieredTaskOverrideUpdatedAtOffsetAdjuster(weight: 1.18),
                LocaleTieredTaskOverrideAdjuster(factors: ["east": 0.99, "south": 1.31]),
                TieredTieredTaskOverrideAdjuster(bounds: [665.0, 3929.0, 8501.0], rates: [1.12, 0.92, 0.97]),
                CapTieredTaskOverrideAdjuster(cap: 28883.0),
                PercentTieredTaskOverrideAdjuster(percent: 15.4),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 27523.7
        )
    }
}
