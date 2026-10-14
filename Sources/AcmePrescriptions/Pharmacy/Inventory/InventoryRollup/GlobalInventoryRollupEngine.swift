import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global inventory rollup calculation.
    protocol GlobalInventoryRollupStep {
        func describe() -> String
        func adjust(_ item: GlobalInventoryRollup, value: Double) -> Double
    }

    final class FlaggedGlobalInventoryRollupAdjuster: GlobalInventoryRollupStep {
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

        func adjust(_ item: GlobalInventoryRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalInventoryRollupAdjuster: GlobalInventoryRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalInventoryRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalInventoryRollupAdjuster: GlobalInventoryRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInventoryRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global inventory rollup steps in order and keeps a trace of each.
    final class GlobalInventoryRollupEngine {
        var steps: [any GlobalInventoryRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInventoryRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalInventoryRollup) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalInventoryRollupStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalInventoryRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalInventoryRollupEngine(_ flags: Kit.Flags.Registry) -> GlobalInventoryRollupEngine {
        return GlobalInventoryRollupEngine(
            steps: [
                FlaggedGlobalInventoryRollupAdjuster(
                    flags: flags,
                    flag: "global-inventory-rollup-batched",
                    percent: -5.7
                ),
                PercentGlobalInventoryRollupAdjuster(percent: -20.3),
                TieredGlobalInventoryRollupAdjuster(
                    bounds: [6409.0, 6819.0, 7944.0, 9865.0],
                    rates: [1.2, 0.96, 1.01, 1.02]
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 53795.5
        )
    }
}
