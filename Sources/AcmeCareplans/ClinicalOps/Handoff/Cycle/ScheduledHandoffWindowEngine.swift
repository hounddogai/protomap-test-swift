import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled handoff window calculation.
    protocol ScheduledHandoffWindowStep {
        func describe() -> String
        func adjust(_ item: ScheduledHandoffWindow, value: Double) -> Double
    }

    final class ChannelScheduledHandoffWindowAdjuster: ScheduledHandoffWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ScheduledHandoffWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledHandoffWindowAdjuster: ScheduledHandoffWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledHandoffWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledHandoffWindowAdjuster: ScheduledHandoffWindowStep {
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

        func adjust(_ item: ScheduledHandoffWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledHandoffWindowAdjuster: ScheduledHandoffWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledHandoffWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled handoff window steps in order and keeps a trace of each.
    final class ScheduledHandoffWindowEngine {
        var steps: [any ScheduledHandoffWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledHandoffWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledHandoffWindow) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [ScheduledHandoffWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledHandoffWindowEngine(_ flags: Kit.Flags.Registry) -> ScheduledHandoffWindowEngine {
        return ScheduledHandoffWindowEngine(
            steps: [
                ChannelScheduledHandoffWindowAdjuster(factors: ["retail": 0.93, "online": 1.18]),
                PercentScheduledHandoffWindowAdjuster(percent: 13.6),
                FlaggedScheduledHandoffWindowAdjuster(
                    flags: flags,
                    flag: "scheduled-handoff-window-regional",
                    percent: 1.6
                ),
                CapScheduledHandoffWindowAdjuster(cap: 34074.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 11381.0
        )
    }
}
