import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up notice calculation.
    protocol FollowUpNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpNotice, value: Double) -> Double
    }

    final class FlaggedFollowUpNoticeAdjuster: FollowUpNoticeAdjuster {
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

        func adjust(_ item: FollowUpNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FollowUpNoticeQuantityOffsetAdjuster: FollowUpNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FollowUpNotice, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapFollowUpNoticeAdjuster: FollowUpNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFollowUpNoticeAdjuster: FollowUpNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameFollowUpNoticeAdjuster: FollowUpNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FollowUpNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the follow up notice steps in order and keeps a trace of each.
    final class FollowUpNoticeEngine {
        var steps: [any FollowUpNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpNotice) -> Double {
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

        func evaluateAll(_ items: [FollowUpNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpNoticeEngine(_ flags: Kit.Flags.Registry) -> FollowUpNoticeEngine {
        return FollowUpNoticeEngine(
            steps: [
                FlaggedFollowUpNoticeAdjuster(flags: flags, flag: "follow-up-notice-primary", percent: -1.6),
                FollowUpNoticeQuantityOffsetAdjuster(weight: 1.33),
                CapFollowUpNoticeAdjuster(cap: 38133.0),
                RoundingFollowUpNoticeAdjuster(step: 5.0),
                NameFollowUpNoticeAdjuster(factors: ["west": 0.93, "retail": 1.3]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 15953.9
        )
    }
}
