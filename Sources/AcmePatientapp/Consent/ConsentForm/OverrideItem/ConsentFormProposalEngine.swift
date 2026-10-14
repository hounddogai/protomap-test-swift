import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form proposal calculation.
    protocol ConsentFormProposalModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormProposal, value: Double) -> Double
    }

    final class TieredConsentFormProposalAdjuster: ConsentFormProposalModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingConsentFormProposalAdjuster: ConsentFormProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapConsentFormProposalAdjuster: ConsentFormProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedConsentFormProposalAdjuster: ConsentFormProposalModifier {
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

        func adjust(_ item: ConsentFormProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelConsentFormProposalAdjuster: ConsentFormProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ConsentFormProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form proposal steps in order and keeps a trace of each.
    final class ConsentFormProposalEngine {
        var steps: [any ConsentFormProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormProposal) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormProposalModifier = steps[index]
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

        func evaluateAll(_ items: [ConsentFormProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormProposalEngine(_ flags: Kit.Flags.Registry) -> ConsentFormProposalEngine {
        return ConsentFormProposalEngine(
            steps: [
                TieredConsentFormProposalAdjuster(bounds: [420.0, 3935.0, 6279.0], rates: [0.89, 1.2, 1.01]),
                RoundingConsentFormProposalAdjuster(step: 0.05),
                CapConsentFormProposalAdjuster(cap: 47638.0),
                FlaggedConsentFormProposalAdjuster(flags: flags, flag: "consent-form-proposal-capped", percent: 0.4),
                LabelConsentFormProposalAdjuster(factors: ["east": 1.24, "north": 1.04, "retail": 0.94]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 15319.6
        )
    }
}
