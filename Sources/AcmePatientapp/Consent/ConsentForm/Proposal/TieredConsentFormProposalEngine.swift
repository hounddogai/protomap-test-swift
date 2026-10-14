import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered consent form proposal calculation.
    protocol TieredConsentFormProposalStep {
        func describe() -> String
        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double
    }

    final class CapTieredConsentFormProposalAdjuster: TieredConsentFormProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredConsentFormProposalAdjuster: TieredConsentFormProposalStep {
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

        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredConsentFormProposalAdjuster: TieredConsentFormProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredConsentFormProposalAdjuster: TieredConsentFormProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredConsentFormProposalPriorityOffsetAdjuster: TieredConsentFormProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class LabelTieredConsentFormProposalAdjuster: TieredConsentFormProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredConsentFormProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered consent form proposal steps in order and keeps a trace of each.
    final class TieredConsentFormProposalEngine {
        var steps: [any TieredConsentFormProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredConsentFormProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredConsentFormProposal) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredConsentFormProposalStep = steps[index]
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

        func evaluateAll(_ items: [TieredConsentFormProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredConsentFormProposalEngine(_ flags: Kit.Flags.Registry) -> TieredConsentFormProposalEngine {
        return TieredConsentFormProposalEngine(
            steps: [
                CapTieredConsentFormProposalAdjuster(cap: 37679.0),
                FlaggedTieredConsentFormProposalAdjuster(
                    flags: flags,
                    flag: "tiered-consent-form-proposal-global",
                    percent: 9.7
                ),
                PercentTieredConsentFormProposalAdjuster(percent: -15.1),
                TieredTieredConsentFormProposalAdjuster(bounds: [4543.0, 9163.0], rates: [1.18, 1.12]),
                TieredConsentFormProposalPriorityOffsetAdjuster(weight: 0.39),
                LabelTieredConsentFormProposalAdjuster(factors: ["south": 0.89, "north": 1.25, "east": 1.16]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 29158.3
        )
    }
}
