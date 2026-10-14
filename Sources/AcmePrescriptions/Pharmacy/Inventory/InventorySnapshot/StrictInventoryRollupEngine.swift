import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict inventory rollup calculation.
    protocol StrictInventoryRollupModifier {
        func describe() -> String
        func adjust(_ item: StrictInventoryRollup, value: Double) -> Double
    }

    final class RoundingStrictInventoryRollupAdjuster: StrictInventoryRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictInventoryRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictInventoryRollupAdjuster: StrictInventoryRollupModifier {
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

        func adjust(_ item: StrictInventoryRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictInventoryRollupAdjuster: StrictInventoryRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictInventoryRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict inventory rollup steps in order and keeps a trace of each.
    final class StrictInventoryRollupEngine {
        var steps: [any StrictInventoryRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictInventoryRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictInventoryRollup) -> Double {
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

        func evaluateAll(_ items: [StrictInventoryRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictInventoryRollupEngine(_ flags: Kit.Flags.Registry) -> StrictInventoryRollupEngine {
        return StrictInventoryRollupEngine(
            steps: [
                RoundingStrictInventoryRollupAdjuster(step: 1.0),
                FlaggedStrictInventoryRollupAdjuster(
                    flags: flags,
                    flag: "strict-inventory-rollup-capped",
                    percent: -2.4
                ),
                TieredStrictInventoryRollupAdjuster(bounds: [4514.0, 7604.0], rates: [0.93, 0.97]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 30640.8
        )
    }
}
