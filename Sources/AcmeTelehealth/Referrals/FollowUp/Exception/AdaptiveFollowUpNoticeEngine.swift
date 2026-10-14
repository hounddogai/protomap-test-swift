import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive follow up notice calculation.
    protocol AdaptiveFollowUpNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double
    }

    final class MinimumAdaptiveFollowUpNoticeAdjuster: AdaptiveFollowUpNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAdaptiveFollowUpNoticeAdjuster: AdaptiveFollowUpNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAdaptiveFollowUpNoticeAdjuster: AdaptiveFollowUpNoticeAdjuster {
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

        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveFollowUpNoticeWindowDaysOffsetAdjuster: AdaptiveFollowUpNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class PercentAdaptiveFollowUpNoticeAdjuster: AdaptiveFollowUpNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveFollowUpNoticeAdjuster: AdaptiveFollowUpNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveFollowUpNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive follow up notice steps in order and keeps a trace of each.
    final class AdaptiveFollowUpNoticeEngine {
        var steps: [any AdaptiveFollowUpNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFollowUpNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveFollowUpNotice) -> Double {
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

        func evaluateAll(_ items: [AdaptiveFollowUpNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFollowUpNoticeEngine(_ flags: Kit.Flags.Registry) -> AdaptiveFollowUpNoticeEngine {
        return AdaptiveFollowUpNoticeEngine(
            steps: [
                MinimumAdaptiveFollowUpNoticeAdjuster(minimum: 1.4),
                CapAdaptiveFollowUpNoticeAdjuster(cap: 6865.0),
                FlaggedAdaptiveFollowUpNoticeAdjuster(
                    flags: flags,
                    flag: "adaptive-follow-up-notice-lenient",
                    percent: -5.5
                ),
                AdaptiveFollowUpNoticeWindowDaysOffsetAdjuster(weight: 1.98),
                PercentAdaptiveFollowUpNoticeAdjuster(percent: -7.0),
                RoundingAdaptiveFollowUpNoticeAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 13378.2
        )
    }
}
