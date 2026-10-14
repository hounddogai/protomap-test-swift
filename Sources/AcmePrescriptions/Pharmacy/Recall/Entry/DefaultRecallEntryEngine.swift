import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default recall entry calculation.
    protocol DefaultRecallEntryFactor {
        func describe() -> String
        func adjust(_ item: DefaultRecallEntry, value: Double) -> Double
    }

    final class RoundingDefaultRecallEntryAdjuster: DefaultRecallEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRecallEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultRecallEntryAdjuster: DefaultRecallEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRecallEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultRecallEntryAdjuster: DefaultRecallEntryFactor {
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

        func adjust(_ item: DefaultRecallEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultRecallEntryAdjuster: DefaultRecallEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRecallEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default recall entry steps in order and keeps a trace of each.
    final class DefaultRecallEntryEngine {
        var steps: [any DefaultRecallEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRecallEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRecallEntry) -> Double {
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

        func evaluateAll(_ items: [DefaultRecallEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRecallEntryEngine(_ flags: Kit.Flags.Registry) -> DefaultRecallEntryEngine {
        return DefaultRecallEntryEngine(
            steps: [
                RoundingDefaultRecallEntryAdjuster(step: 0.1),
                CapDefaultRecallEntryAdjuster(cap: 45777.0),
                FlaggedDefaultRecallEntryAdjuster(flags: flags, flag: "default-recall-entry-legacy", percent: 9.5),
                TieredDefaultRecallEntryAdjuster(
                    bounds: [457.0, 5353.0, 7374.0, 8209.0],
                    rates: [1.11, 1.1, 1.01, 0.97]
                ),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 1243.7
        )
    }
}
