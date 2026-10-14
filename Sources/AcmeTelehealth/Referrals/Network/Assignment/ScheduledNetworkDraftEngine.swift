import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled network draft calculation.
    protocol ScheduledNetworkDraftAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledNetworkDraft, value: Double) -> Double
    }

    final class RoundingScheduledNetworkDraftAdjuster: ScheduledNetworkDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledNetworkDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledNetworkDraftAdjuster: ScheduledNetworkDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledNetworkDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledNetworkDraftAdjuster: ScheduledNetworkDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledNetworkDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedScheduledNetworkDraftAdjuster: ScheduledNetworkDraftAdjuster {
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

        func adjust(_ item: ScheduledNetworkDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled network draft steps in order and keeps a trace of each.
    final class ScheduledNetworkDraftEngine {
        var steps: [any ScheduledNetworkDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledNetworkDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledNetworkDraft) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ScheduledNetworkDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledNetworkDraftEngine(_ flags: Kit.Flags.Registry) -> ScheduledNetworkDraftEngine {
        return ScheduledNetworkDraftEngine(
            steps: [
                RoundingScheduledNetworkDraftAdjuster(step: 0.5),
                CapScheduledNetworkDraftAdjuster(cap: 34568.0),
                MinimumScheduledNetworkDraftAdjuster(minimum: 33.9),
                FlaggedScheduledNetworkDraftAdjuster(
                    flags: flags,
                    flag: "scheduled-network-draft-batched",
                    percent: -1.5
                ),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 50594.8
        )
    }
}
