import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure score calculation.
    protocol DisclosureScoreAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureScore, value: Double) -> Double
    }

    final class CapDisclosureScoreAdjuster: DisclosureScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDisclosureScoreAdjuster: DisclosureScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDisclosureScoreAdjuster: DisclosureScoreAdjuster {
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

        func adjust(_ item: DisclosureScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DisclosureScoreCopayOffsetAdjuster: DisclosureScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: DisclosureScore, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the disclosure score steps in order and keeps a trace of each.
    final class DisclosureScoreEngine {
        var steps: [any DisclosureScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureScore) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [DisclosureScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureScoreEngine(_ flags: Kit.Flags.Registry) -> DisclosureScoreEngine {
        return DisclosureScoreEngine(
            steps: [
                CapDisclosureScoreAdjuster(cap: 47652.0),
                PercentDisclosureScoreAdjuster(percent: 19.5),
                FlaggedDisclosureScoreAdjuster(flags: flags, flag: "disclosure-score-regional", percent: -3.0),
                DisclosureScoreCopayOffsetAdjuster(weight: 1.41),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 24601.3
        )
    }
}
