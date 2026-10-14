import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census entry calculation.
    protocol CensusEntryFactor {
        func describe() -> String
        func adjust(_ item: CensusEntry, value: Double) -> Double
    }

    final class PercentCensusEntryAdjuster: CensusEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CensusEntryRateOffsetAdjuster: CensusEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: CensusEntry, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class RoundingCensusEntryAdjuster: CensusEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameCensusEntryAdjuster: CensusEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CensusEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCensusEntryAdjuster: CensusEntryFactor {
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

        func adjust(_ item: CensusEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCensusEntryAdjuster: CensusEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the census entry steps in order and keeps a trace of each.
    final class CensusEntryEngine {
        var steps: [any CensusEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusEntry) -> Double {
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

        func evaluateAll(_ items: [CensusEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusEntryEngine(_ flags: Kit.Flags.Registry) -> CensusEntryEngine {
        return CensusEntryEngine(
            steps: [
                PercentCensusEntryAdjuster(percent: -21.6),
                CensusEntryRateOffsetAdjuster(weight: 0.42),
                RoundingCensusEntryAdjuster(step: 0.1),
                NameCensusEntryAdjuster(factors: ["online": 0.8]),
                FlaggedCensusEntryAdjuster(flags: flags, flag: "census-entry-tiered", percent: -5.4),
                CapCensusEntryAdjuster(cap: 5517.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 29203.5
        )
    }
}
