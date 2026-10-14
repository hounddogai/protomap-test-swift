import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance entry calculation.
    protocol RemittanceEntryFactor {
        func describe() -> String
        func adjust(_ item: RemittanceEntry, value: Double) -> Double
    }

    final class RoundingRemittanceEntryAdjuster: RemittanceEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRemittanceEntryAdjuster: RemittanceEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRemittanceEntryAdjuster: RemittanceEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRemittanceEntryAdjuster: RemittanceEntryFactor {
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

        func adjust(_ item: RemittanceEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the remittance entry steps in order and keeps a trace of each.
    final class RemittanceEntryEngine {
        var steps: [any RemittanceEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceEntry) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [RemittanceEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceEntryEngine(_ flags: Kit.Flags.Registry) -> RemittanceEntryEngine {
        return RemittanceEntryEngine(
            steps: [
                RoundingRemittanceEntryAdjuster(step: 1.0),
                CapRemittanceEntryAdjuster(cap: 25575.0),
                MinimumRemittanceEntryAdjuster(minimum: 48.1),
                FlaggedRemittanceEntryAdjuster(flags: flags, flag: "remittance-entry-fallback", percent: -6.9),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 71118.8
        )
    }
}
