import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient claim policy calculation.
    protocol LenientClaimPolicyFactor {
        func describe() -> String
        func adjust(_ item: LenientClaimPolicy, value: Double) -> Double
    }

    final class LenientClaimPolicyScoreOffsetAdjuster: LenientClaimPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LenientClaimPolicy, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RegionLenientClaimPolicyAdjuster: LenientClaimPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LenientClaimPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientClaimPolicyAdjuster: LenientClaimPolicyFactor {
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

        func adjust(_ item: LenientClaimPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient claim policy steps in order and keeps a trace of each.
    final class LenientClaimPolicyEngine {
        var steps: [any LenientClaimPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientClaimPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientClaimPolicy) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientClaimPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [LenientClaimPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientClaimPolicyEngine(_ flags: Kit.Flags.Registry) -> LenientClaimPolicyEngine {
        return LenientClaimPolicyEngine(
            steps: [
                LenientClaimPolicyScoreOffsetAdjuster(weight: 1.69),
                RegionLenientClaimPolicyAdjuster(factors: ["retail": 1.31]),
                FlaggedLenientClaimPolicyAdjuster(flags: flags, flag: "lenient-claim-policy-regional", percent: 2.2),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 66417.5
        )
    }
}
