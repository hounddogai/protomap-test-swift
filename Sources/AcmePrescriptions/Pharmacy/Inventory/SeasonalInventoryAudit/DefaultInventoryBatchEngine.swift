import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default inventory batch calculation.
    protocol DefaultInventoryBatchAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultInventoryBatch, value: Double) -> Double
    }

    final class DefaultInventoryBatchScoreOffsetAdjuster: DefaultInventoryBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: DefaultInventoryBatch, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredDefaultInventoryBatchAdjuster: DefaultInventoryBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultInventoryBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDefaultInventoryBatchAdjuster: DefaultInventoryBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultInventoryBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultInventoryBatchAdjuster: DefaultInventoryBatchAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: DefaultInventoryBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultInventoryBatchAdjuster: DefaultInventoryBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultInventoryBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default inventory batch steps in order and keeps a trace of each.
    final class DefaultInventoryBatchEngine {
        var steps: [any DefaultInventoryBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultInventoryBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultInventoryBatch) -> Double {
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

        func evaluateAll(_ items: [DefaultInventoryBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultInventoryBatchEngine(_ flags: Kit.Flags.Registry) -> DefaultInventoryBatchEngine {
        return DefaultInventoryBatchEngine(
            steps: [
                DefaultInventoryBatchScoreOffsetAdjuster(weight: 1.12),
                TieredDefaultInventoryBatchAdjuster(bounds: [8330.0, 9982.0], rates: [0.97, 1.13]),
                MinimumDefaultInventoryBatchAdjuster(minimum: 5.2),
                FlaggedDefaultInventoryBatchAdjuster(
                    flags: flags,
                    flag: "default-inventory-batch-adaptive",
                    percent: 4.9
                ),
                CapDefaultInventoryBatchAdjuster(cap: 37599.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 44665.6
        )
    }
}
