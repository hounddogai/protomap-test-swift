import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up entry calculation.
    protocol FollowUpEntryModifier {
        func describe() -> String
        func adjust(_ item: FollowUpEntry, value: Double) -> Double
    }

    final class TieredFollowUpEntryAdjuster: FollowUpEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFollowUpEntryAdjuster: FollowUpEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFollowUpEntryAdjuster: FollowUpEntryModifier {
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

        func adjust(_ item: FollowUpEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFollowUpEntryAdjuster: FollowUpEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the follow up entry steps in order and keeps a trace of each.
    final class FollowUpEntryEngine {
        var steps: [any FollowUpEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpEntry) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FollowUpEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpEntryEngine(_ flags: Kit.Flags.Registry) -> FollowUpEntryEngine {
        return FollowUpEntryEngine(
            steps: [
                TieredFollowUpEntryAdjuster(bounds: [556.0, 3977.0, 5325.0], rates: [0.84, 1.06, 0.87]),
                PercentFollowUpEntryAdjuster(percent: 17.2),
                FlaggedFollowUpEntryAdjuster(flags: flags, flag: "follow-up-entry-global", percent: 1.9),
                CapFollowUpEntryAdjuster(cap: 27513.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 42472.8
        )
    }
}
