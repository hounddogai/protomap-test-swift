import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global follow up baseline calculation.
    protocol GlobalFollowUpBaselineFactor {
        func describe() -> String
        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double
    }

    final class GlobalFollowUpBaselineEndsAtOffsetAdjuster: GlobalFollowUpBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedGlobalFollowUpBaselineAdjuster: GlobalFollowUpBaselineFactor {
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

        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalFollowUpBaselineAdjuster: GlobalFollowUpBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleGlobalFollowUpBaselineAdjuster: GlobalFollowUpBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalFollowUpBaselineAdjuster: GlobalFollowUpBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalFollowUpBaselineAdjuster: GlobalFollowUpBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalFollowUpBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global follow up baseline steps in order and keeps a trace of each.
    final class GlobalFollowUpBaselineEngine {
        var steps: [any GlobalFollowUpBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalFollowUpBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalFollowUpBaseline) -> Double {
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

        func evaluateAll(_ items: [GlobalFollowUpBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalFollowUpBaselineEngine(_ flags: Kit.Flags.Registry) -> GlobalFollowUpBaselineEngine {
        return GlobalFollowUpBaselineEngine(
            steps: [
                GlobalFollowUpBaselineEndsAtOffsetAdjuster(weight: 1.66),
                FlaggedGlobalFollowUpBaselineAdjuster(
                    flags: flags,
                    flag: "global-follow-up-baseline-manual",
                    percent: -6.4
                ),
                MinimumGlobalFollowUpBaselineAdjuster(minimum: 13.8),
                LocaleGlobalFollowUpBaselineAdjuster(factors: ["east": 0.8, "online": 1.19]),
                PercentGlobalFollowUpBaselineAdjuster(percent: 22.5),
                CapGlobalFollowUpBaselineAdjuster(cap: 11166.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 85827.3
        )
    }
}
