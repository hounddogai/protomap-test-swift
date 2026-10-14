import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up digest calculation.
    protocol FollowUpDigestAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpDigest, value: Double) -> Double
    }

    final class FlaggedFollowUpDigestAdjuster: FollowUpDigestAdjuster {
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

        func adjust(_ item: FollowUpDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFollowUpDigestAdjuster: FollowUpDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FollowUpDigestGraceDaysOffsetAdjuster: FollowUpDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: FollowUpDigest, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapFollowUpDigestAdjuster: FollowUpDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the follow up digest steps in order and keeps a trace of each.
    final class FollowUpDigestEngine {
        var steps: [any FollowUpDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpDigest) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [FollowUpDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpDigestEngine(_ flags: Kit.Flags.Registry) -> FollowUpDigestEngine {
        return FollowUpDigestEngine(
            steps: [
                FlaggedFollowUpDigestAdjuster(flags: flags, flag: "follow-up-digest-strict", percent: 8.8),
                PercentFollowUpDigestAdjuster(percent: -8.6),
                FollowUpDigestGraceDaysOffsetAdjuster(weight: 0.61),
                CapFollowUpDigestAdjuster(cap: 39857.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 37520.1
        )
    }
}
