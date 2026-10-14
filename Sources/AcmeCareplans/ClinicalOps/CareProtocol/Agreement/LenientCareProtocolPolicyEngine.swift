import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient care protocol policy calculation.
    protocol LenientCareProtocolPolicyModifier {
        func describe() -> String
        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double
    }

    final class CapLenientCareProtocolPolicyAdjuster: LenientCareProtocolPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelLenientCareProtocolPolicyAdjuster: LenientCareProtocolPolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientCareProtocolPolicyAdjuster: LenientCareProtocolPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLenientCareProtocolPolicyAdjuster: LenientCareProtocolPolicyModifier {
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

        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientCareProtocolPolicyAdjuster: LenientCareProtocolPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientCareProtocolPolicyAdjuster: LenientCareProtocolPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCareProtocolPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient care protocol policy steps in order and keeps a trace of each.
    final class LenientCareProtocolPolicyEngine {
        var steps: [any LenientCareProtocolPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareProtocolPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCareProtocolPolicy) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [LenientCareProtocolPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCareProtocolPolicyEngine(_ flags: Kit.Flags.Registry) -> LenientCareProtocolPolicyEngine {
        return LenientCareProtocolPolicyEngine(
            steps: [
                CapLenientCareProtocolPolicyAdjuster(cap: 21591.0),
                ChannelLenientCareProtocolPolicyAdjuster(factors: ["west": 1.12, "online": 0.72]),
                MinimumLenientCareProtocolPolicyAdjuster(minimum: 18.9),
                FlaggedLenientCareProtocolPolicyAdjuster(
                    flags: flags,
                    flag: "lenient-care-protocol-policy-regional",
                    percent: -3.2
                ),
                PercentLenientCareProtocolPolicyAdjuster(percent: -18.8),
                RoundingLenientCareProtocolPolicyAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 73160.3
        )
    }
}
