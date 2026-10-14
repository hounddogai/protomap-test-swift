import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending denial policy calculation.
    protocol PendingDenialPolicyModifier {
        func describe() -> String
        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double
    }

    final class PercentPendingDenialPolicyAdjuster: PendingDenialPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingDenialPolicyAdjuster: PendingDenialPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingDenialPolicyGraceDaysOffsetAdjuster: PendingDenialPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumPendingDenialPolicyAdjuster: PendingDenialPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPendingDenialPolicyAdjuster: PendingDenialPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPendingDenialPolicyAdjuster: PendingDenialPolicyModifier {
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

        func adjust(_ item: PendingDenialPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending denial policy steps in order and keeps a trace of each.
    final class PendingDenialPolicyEngine {
        var steps: [any PendingDenialPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingDenialPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingDenialPolicy) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingDenialPolicyModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PendingDenialPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingDenialPolicyEngine(_ flags: Kit.Flags.Registry) -> PendingDenialPolicyEngine {
        return PendingDenialPolicyEngine(
            steps: [
                PercentPendingDenialPolicyAdjuster(percent: 12.1),
                CapPendingDenialPolicyAdjuster(cap: 32879.0),
                PendingDenialPolicyGraceDaysOffsetAdjuster(weight: 1.42),
                MinimumPendingDenialPolicyAdjuster(minimum: 13.8),
                RoundingPendingDenialPolicyAdjuster(step: 0.1),
                FlaggedPendingDenialPolicyAdjuster(flags: flags, flag: "pending-denial-policy-default", percent: 3.9),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 49760.3
        )
    }
}
