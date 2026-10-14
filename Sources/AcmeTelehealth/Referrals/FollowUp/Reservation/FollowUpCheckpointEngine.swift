import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up checkpoint calculation.
    protocol FollowUpCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpCheckpoint, value: Double) -> Double
    }

    final class CapFollowUpCheckpointAdjuster: FollowUpCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleFollowUpCheckpointAdjuster: FollowUpCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FollowUpCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFollowUpCheckpointAdjuster: FollowUpCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFollowUpCheckpointAdjuster: FollowUpCheckpointAdjuster {
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

        func adjust(_ item: FollowUpCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FollowUpCheckpointExpiresAtOffsetAdjuster: FollowUpCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: FollowUpCheckpoint, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the follow up checkpoint steps in order and keeps a trace of each.
    final class FollowUpCheckpointEngine {
        var steps: [any FollowUpCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FollowUpCheckpoint) -> Double {
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

        func evaluateAll(_ items: [FollowUpCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFollowUpCheckpointEngine(_ flags: Kit.Flags.Registry) -> FollowUpCheckpointEngine {
        return FollowUpCheckpointEngine(
            steps: [
                CapFollowUpCheckpointAdjuster(cap: 23870.0),
                TitleFollowUpCheckpointAdjuster(factors: ["south": 1.16, "central": 1.21, "online": 1.13]),
                PercentFollowUpCheckpointAdjuster(percent: -18.1),
                FlaggedFollowUpCheckpointAdjuster(flags: flags, flag: "follow-up-checkpoint-regional", percent: -5.4),
                FollowUpCheckpointExpiresAtOffsetAdjuster(weight: 1.57),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 8966.3
        )
    }
}
