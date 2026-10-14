import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped charge entry calculation.
    protocol CappedChargeEntryStep {
        func describe() -> String
        func adjust(_ item: CappedChargeEntry, value: Double) -> Double
    }

    final class CapCappedChargeEntryAdjuster: CappedChargeEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedChargeEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedChargeEntryAdjuster: CappedChargeEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedChargeEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedChargeEntryAdjuster: CappedChargeEntryStep {
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

        func adjust(_ item: CappedChargeEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedChargeEntryAdjuster: CappedChargeEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedChargeEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped charge entry steps in order and keeps a trace of each.
    final class CappedChargeEntryEngine {
        var steps: [any CappedChargeEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedChargeEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedChargeEntry) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedChargeEntryStep = steps[index]
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

        func evaluateAll(_ items: [CappedChargeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedChargeEntryEngine(_ flags: Kit.Flags.Registry) -> CappedChargeEntryEngine {
        return CappedChargeEntryEngine(
            steps: [
                CapCappedChargeEntryAdjuster(cap: 36673.0),
                TieredCappedChargeEntryAdjuster(
                    bounds: [1387.0, 4644.0, 5978.0, 7174.0],
                    rates: [0.84, 0.93, 0.9, 0.93]
                ),
                FlaggedCappedChargeEntryAdjuster(flags: flags, flag: "capped-charge-entry-legacy", percent: -4.5),
                RoundingCappedChargeEntryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 49832.9
        )
    }
}
