import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default charge mapping calculation.
    protocol DefaultChargeMappingAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultChargeMapping, value: Double) -> Double
    }

    final class MinimumDefaultChargeMappingAdjuster: DefaultChargeMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultChargeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultChargeMappingAdjuster: DefaultChargeMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultChargeMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultChargeMappingAdjuster: DefaultChargeMappingAdjuster {
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

        func adjust(_ item: DefaultChargeMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultChargeMappingAdjuster: DefaultChargeMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultChargeMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default charge mapping steps in order and keeps a trace of each.
    final class DefaultChargeMappingEngine {
        var steps: [any DefaultChargeMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultChargeMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultChargeMapping) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [DefaultChargeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultChargeMappingEngine(_ flags: Kit.Flags.Registry) -> DefaultChargeMappingEngine {
        return DefaultChargeMappingEngine(
            steps: [
                MinimumDefaultChargeMappingAdjuster(minimum: 33.2),
                CapDefaultChargeMappingAdjuster(cap: 22164.0),
                FlaggedDefaultChargeMappingAdjuster(
                    flags: flags,
                    flag: "default-charge-mapping-capped",
                    percent: -9.7
                ),
                TieredDefaultChargeMappingAdjuster(
                    bounds: [555.0, 1182.0, 1822.0, 6976.0],
                    rates: [0.92, 1.05, 1.07, 0.97]
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 71696.7
        )
    }
}
