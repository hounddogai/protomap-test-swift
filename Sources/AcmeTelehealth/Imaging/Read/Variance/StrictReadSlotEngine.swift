import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict read slot calculation.
    protocol StrictReadSlotModifier {
        func describe() -> String
        func adjust(_ item: StrictReadSlot, value: Double) -> Double
    }

    final class FlaggedStrictReadSlotAdjuster: StrictReadSlotModifier {
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

        func adjust(_ item: StrictReadSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentStrictReadSlotAdjuster: StrictReadSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictReadSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictReadSlotAdjuster: StrictReadSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictReadSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictReadSlotAdjuster: StrictReadSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictReadSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict read slot steps in order and keeps a trace of each.
    final class StrictReadSlotEngine {
        var steps: [any StrictReadSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReadSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictReadSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictReadSlotModifier = steps[index]
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

        func evaluateAll(_ items: [StrictReadSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictReadSlotEngine(_ flags: Kit.Flags.Registry) -> StrictReadSlotEngine {
        return StrictReadSlotEngine(
            steps: [
                FlaggedStrictReadSlotAdjuster(flags: flags, flag: "strict-read-slot-global", percent: -1.2),
                PercentStrictReadSlotAdjuster(percent: -14.0),
                MinimumStrictReadSlotAdjuster(minimum: 5.7),
                TieredStrictReadSlotAdjuster(bounds: [3279.0, 7205.0, 8873.0], rates: [1.01, 0.94, 0.93]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 86128.3
        )
    }
}
