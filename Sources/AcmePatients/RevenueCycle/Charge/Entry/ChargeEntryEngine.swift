import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge entry calculation.
    protocol ChargeEntryModifier {
        func describe() -> String
        func adjust(_ item: ChargeEntry, value: Double) -> Double
    }

    final class TieredChargeEntryAdjuster: ChargeEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapChargeEntryAdjuster: ChargeEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedChargeEntryAdjuster: ChargeEntryModifier {
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

        func adjust(_ item: ChargeEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge entry steps in order and keeps a trace of each.
    final class ChargeEntryEngine {
        var steps: [any ChargeEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeEntry) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ChargeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeEntryEngine(_ flags: Kit.Flags.Registry) -> ChargeEntryEngine {
        return ChargeEntryEngine(
            steps: [
                TieredChargeEntryAdjuster(bounds: [2352.0, 2459.0, 2872.0, 9546.0], rates: [0.96, 0.87, 1.12, 0.92]),
                CapChargeEntryAdjuster(cap: 4128.0),
                FlaggedChargeEntryAdjuster(flags: flags, flag: "charge-entry-weighted", percent: -6.3),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 82762.3
        )
    }
}
