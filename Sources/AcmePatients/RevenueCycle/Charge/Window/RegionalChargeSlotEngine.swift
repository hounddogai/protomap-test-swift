import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional charge slot calculation.
    protocol RegionalChargeSlotModifier {
        func describe() -> String
        func adjust(_ item: RegionalChargeSlot, value: Double) -> Double
    }

    final class PercentRegionalChargeSlotAdjuster: RegionalChargeSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalChargeSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalChargeSlotAdjuster: RegionalChargeSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalChargeSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRegionalChargeSlotAdjuster: RegionalChargeSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalChargeSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalChargeSlotAdjuster: RegionalChargeSlotModifier {
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

        func adjust(_ item: RegionalChargeSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalChargeSlotAdjuster: RegionalChargeSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalChargeSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional charge slot steps in order and keeps a trace of each.
    final class RegionalChargeSlotEngine {
        var steps: [any RegionalChargeSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalChargeSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalChargeSlot) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalChargeSlotModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalChargeSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalChargeSlotEngine(_ flags: Kit.Flags.Registry) -> RegionalChargeSlotEngine {
        return RegionalChargeSlotEngine(
            steps: [
                PercentRegionalChargeSlotAdjuster(percent: 9.9),
                TieredRegionalChargeSlotAdjuster(
                    bounds: [1915.0, 4825.0, 5671.0, 6143.0],
                    rates: [1.0, 1.09, 1.09, 0.83]
                ),
                CapRegionalChargeSlotAdjuster(cap: 43955.0),
                FlaggedRegionalChargeSlotAdjuster(flags: flags, flag: "regional-charge-slot-legacy", percent: 3.2),
                RoundingRegionalChargeSlotAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 58688.8
        )
    }
}
