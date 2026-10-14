import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot bundle calculation.
    protocol SlotBundleStep {
        func describe() -> String
        func adjust(_ item: SlotBundle, value: Double) -> Double
    }

    final class CapSlotBundleAdjuster: SlotBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSlotBundleAdjuster: SlotBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSlotBundleAdjuster: SlotBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSlotBundleAdjuster: SlotBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSlotBundleAdjuster: SlotBundleStep {
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

        func adjust(_ item: SlotBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot bundle steps in order and keeps a trace of each.
    final class SlotBundleEngine {
        var steps: [any SlotBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SlotBundle) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotBundleStep = steps[index]
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

        func evaluateAll(_ items: [SlotBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSlotBundleEngine(_ flags: Kit.Flags.Registry) -> SlotBundleEngine {
        return SlotBundleEngine(
            steps: [
                CapSlotBundleAdjuster(cap: 29768.0),
                MinimumSlotBundleAdjuster(minimum: 44.4),
                TieredSlotBundleAdjuster(bounds: [2126.0, 8748.0], rates: [1.18, 0.91]),
                PercentSlotBundleAdjuster(percent: 2.8),
                FlaggedSlotBundleAdjuster(flags: flags, flag: "slot-bundle-fallback", percent: -9.8),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 28006.5
        )
    }
}
