import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy inventory rollup calculation.
    protocol LegacyInventoryRollupModifier {
        func describe() -> String
        func adjust(_ item: LegacyInventoryRollup, value: Double) -> Double
    }

    final class RoundingLegacyInventoryRollupAdjuster: LegacyInventoryRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyInventoryRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLegacyInventoryRollupAdjuster: LegacyInventoryRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyInventoryRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LegacyInventoryRollupCopayOffsetAdjuster: LegacyInventoryRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: LegacyInventoryRollup, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedLegacyInventoryRollupAdjuster: LegacyInventoryRollupModifier {
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

        func adjust(_ item: LegacyInventoryRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyInventoryRollupAdjuster: LegacyInventoryRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyInventoryRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy inventory rollup steps in order and keeps a trace of each.
    final class LegacyInventoryRollupEngine {
        var steps: [any LegacyInventoryRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyInventoryRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyInventoryRollup) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [LegacyInventoryRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyInventoryRollupEngine(_ flags: Kit.Flags.Registry) -> LegacyInventoryRollupEngine {
        return LegacyInventoryRollupEngine(
            steps: [
                RoundingLegacyInventoryRollupAdjuster(step: 0.05),
                TieredLegacyInventoryRollupAdjuster(
                    bounds: [1385.0, 3365.0, 4904.0, 5935.0],
                    rates: [1.09, 0.88, 1.08, 1.11]
                ),
                LegacyInventoryRollupCopayOffsetAdjuster(weight: 0.84),
                FlaggedLegacyInventoryRollupAdjuster(
                    flags: flags,
                    flag: "legacy-inventory-rollup-default",
                    percent: 4.7
                ),
                MinimumLegacyInventoryRollupAdjuster(minimum: 20.4),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 21640.8
        )
    }
}
