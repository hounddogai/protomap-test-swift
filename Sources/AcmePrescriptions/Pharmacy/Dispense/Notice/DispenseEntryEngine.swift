import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense entry calculation.
    protocol DispenseEntryStep {
        func describe() -> String
        func adjust(_ item: DispenseEntry, value: Double) -> Double
    }

    final class CapDispenseEntryAdjuster: DispenseEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDispenseEntryAdjuster: DispenseEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDispenseEntryAdjuster: DispenseEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDispenseEntryAdjuster: DispenseEntryStep {
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

        func adjust(_ item: DispenseEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDispenseEntryAdjuster: DispenseEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DispenseEntryDiscountOffsetAdjuster: DispenseEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: DispenseEntry, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the dispense entry steps in order and keeps a trace of each.
    final class DispenseEntryEngine {
        var steps: [any DispenseEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DispenseEntry) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [DispenseEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDispenseEntryEngine(_ flags: Kit.Flags.Registry) -> DispenseEntryEngine {
        return DispenseEntryEngine(
            steps: [
                CapDispenseEntryAdjuster(cap: 10668.0),
                TieredDispenseEntryAdjuster(bounds: [1628.0, 8552.0], rates: [0.81, 0.85]),
                RoundingDispenseEntryAdjuster(step: 0.05),
                FlaggedDispenseEntryAdjuster(flags: flags, flag: "dispense-entry-fallback", percent: 6.9),
                PercentDispenseEntryAdjuster(percent: 16.7),
                DispenseEntryDiscountOffsetAdjuster(weight: 1.32),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 63343.2
        )
    }
}
