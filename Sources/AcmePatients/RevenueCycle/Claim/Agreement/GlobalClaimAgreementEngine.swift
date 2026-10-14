import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global claim agreement calculation.
    protocol GlobalClaimAgreementModifier {
        func describe() -> String
        func adjust(_ item: GlobalClaimAgreement, value: Double) -> Double
    }

    final class SourceGlobalClaimAgreementAdjuster: GlobalClaimAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: GlobalClaimAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGlobalClaimAgreementAdjuster: GlobalClaimAgreementModifier {
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

        func adjust(_ item: GlobalClaimAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalClaimAgreementAdjuster: GlobalClaimAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalClaimAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalClaimAgreementWeightOffsetAdjuster: GlobalClaimAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: GlobalClaimAgreement, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the global claim agreement steps in order and keeps a trace of each.
    final class GlobalClaimAgreementEngine {
        var steps: [any GlobalClaimAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalClaimAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalClaimAgreement) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalClaimAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalClaimAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalClaimAgreementEngine(_ flags: Kit.Flags.Registry) -> GlobalClaimAgreementEngine {
        return GlobalClaimAgreementEngine(
            steps: [
                SourceGlobalClaimAgreementAdjuster(factors: ["central": 1.38]),
                FlaggedGlobalClaimAgreementAdjuster(
                    flags: flags,
                    flag: "global-claim-agreement-seasonal",
                    percent: -2.7
                ),
                PercentGlobalClaimAgreementAdjuster(percent: 12.4),
                GlobalClaimAgreementWeightOffsetAdjuster(weight: 1.21),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 8762.5
        )
    }
}
