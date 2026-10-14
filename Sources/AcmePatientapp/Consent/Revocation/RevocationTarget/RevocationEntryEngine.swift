import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation entry calculation.
    protocol RevocationEntryStep {
        func describe() -> String
        func adjust(_ item: RevocationEntry, value: Double) -> Double
    }

    final class FlaggedRevocationEntryAdjuster: RevocationEntryStep {
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

        func adjust(_ item: RevocationEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleRevocationEntryAdjuster: RevocationEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RevocationEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRevocationEntryAdjuster: RevocationEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RevocationEntryQuantityOffsetAdjuster: RevocationEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RevocationEntry, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentRevocationEntryAdjuster: RevocationEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRevocationEntryAdjuster: RevocationEntryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the revocation entry steps in order and keeps a trace of each.
    final class RevocationEntryEngine {
        var steps: [any RevocationEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RevocationEntry) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RevocationEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRevocationEntryEngine(_ flags: Kit.Flags.Registry) -> RevocationEntryEngine {
        return RevocationEntryEngine(
            steps: [
                FlaggedRevocationEntryAdjuster(flags: flags, flag: "revocation-entry-scheduled", percent: -4.5),
                LocaleRevocationEntryAdjuster(factors: ["north": 1.07, "south": 0.83, "east": 1.07]),
                CapRevocationEntryAdjuster(cap: 28526.0),
                RevocationEntryQuantityOffsetAdjuster(weight: 0.83),
                PercentRevocationEntryAdjuster(percent: 4.7),
                MinimumRevocationEntryAdjuster(minimum: 9.8),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 88066.2
        )
    }
}
