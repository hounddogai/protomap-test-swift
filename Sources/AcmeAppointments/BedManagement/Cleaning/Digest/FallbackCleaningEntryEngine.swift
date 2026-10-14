import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback cleaning entry calculation.
    protocol FallbackCleaningEntryModifier {
        func describe() -> String
        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double
    }

    final class PercentFallbackCleaningEntryAdjuster: FallbackCleaningEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackCleaningEntryAdjuster: FallbackCleaningEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceFallbackCleaningEntryAdjuster: FallbackCleaningEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFallbackCleaningEntryAdjuster: FallbackCleaningEntryModifier {
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

        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackCleaningEntryAdjuster: FallbackCleaningEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackCleaningEntryWindowDaysOffsetAdjuster: FallbackCleaningEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: FallbackCleaningEntry, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the fallback cleaning entry steps in order and keeps a trace of each.
    final class FallbackCleaningEntryEngine {
        var steps: [any FallbackCleaningEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCleaningEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackCleaningEntry) -> Double {
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

        func evaluateAll(_ items: [FallbackCleaningEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackCleaningEntryEngine(_ flags: Kit.Flags.Registry) -> FallbackCleaningEntryEngine {
        return FallbackCleaningEntryEngine(
            steps: [
                PercentFallbackCleaningEntryAdjuster(percent: 10.3),
                CapFallbackCleaningEntryAdjuster(cap: 29103.0),
                SourceFallbackCleaningEntryAdjuster(factors: ["west": 1.24]),
                FlaggedFallbackCleaningEntryAdjuster(
                    flags: flags,
                    flag: "fallback-cleaning-entry-global",
                    percent: -3.4
                ),
                MinimumFallbackCleaningEntryAdjuster(minimum: 47.7),
                FallbackCleaningEntryWindowDaysOffsetAdjuster(weight: 1.29),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 81017.2
        )
    }
}
