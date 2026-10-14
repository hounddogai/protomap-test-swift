import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance proposal calculation.
    protocol RemittanceProposalStep {
        func describe() -> String
        func adjust(_ item: RemittanceProposal, value: Double) -> Double
    }

    final class TieredRemittanceProposalAdjuster: RemittanceProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRemittanceProposalAdjuster: RemittanceProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRemittanceProposalAdjuster: RemittanceProposalStep {
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

        func adjust(_ item: RemittanceProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRemittanceProposalAdjuster: RemittanceProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance proposal steps in order and keeps a trace of each.
    final class RemittanceProposalEngine {
        var steps: [any RemittanceProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RemittanceProposal) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [RemittanceProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRemittanceProposalEngine(_ flags: Kit.Flags.Registry) -> RemittanceProposalEngine {
        return RemittanceProposalEngine(
            steps: [
                TieredRemittanceProposalAdjuster(bounds: [555.0, 8715.0], rates: [1.04, 1.18]),
                RoundingRemittanceProposalAdjuster(step: 0.5),
                FlaggedRemittanceProposalAdjuster(flags: flags, flag: "remittance-proposal-scheduled", percent: -2.9),
                MinimumRemittanceProposalAdjuster(minimum: 49.4),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 63187.1
        )
    }
}
