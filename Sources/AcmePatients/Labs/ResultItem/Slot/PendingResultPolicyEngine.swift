import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending result policy calculation.
    protocol PendingResultPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: PendingResultPolicy, value: Double) -> Double
    }

    final class CapPendingResultPolicyAdjuster: PendingResultPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingResultPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingResultPolicyAdjuster: PendingResultPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingResultPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPendingResultPolicyAdjuster: PendingResultPolicyAdjuster {
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

        func adjust(_ item: PendingResultPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending result policy steps in order and keeps a trace of each.
    final class PendingResultPolicyEngine {
        var steps: [any PendingResultPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingResultPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingResultPolicy) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [PendingResultPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingResultPolicyEngine(_ flags: Kit.Flags.Registry) -> PendingResultPolicyEngine {
        return PendingResultPolicyEngine(
            steps: [
                CapPendingResultPolicyAdjuster(cap: 20958.0),
                PercentPendingResultPolicyAdjuster(percent: -12.1),
                FlaggedPendingResultPolicyAdjuster(flags: flags, flag: "pending-result-policy-manual", percent: -7.1),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 98917.0
        )
    }
}
