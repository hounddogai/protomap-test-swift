import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach proposal calculation.
    protocol OutreachProposalFactor {
        func describe() -> String
        func adjust(_ item: OutreachProposal, value: Double) -> Double
    }

    final class PercentOutreachProposalAdjuster: OutreachProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOutreachProposalAdjuster: OutreachProposalFactor {
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

        func adjust(_ item: OutreachProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOutreachProposalAdjuster: OutreachProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumOutreachProposalAdjuster: OutreachProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the outreach proposal steps in order and keeps a trace of each.
    final class OutreachProposalEngine {
        var steps: [any OutreachProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachProposal) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [OutreachProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachProposalEngine(_ flags: Kit.Flags.Registry) -> OutreachProposalEngine {
        return OutreachProposalEngine(
            steps: [
                PercentOutreachProposalAdjuster(percent: -18.2),
                FlaggedOutreachProposalAdjuster(flags: flags, flag: "outreach-proposal-rolling", percent: 8.2),
                TieredOutreachProposalAdjuster(
                    bounds: [427.0, 5935.0, 7185.0, 9255.0],
                    rates: [0.93, 1.05, 0.92, 1.02]
                ),
                MinimumOutreachProposalAdjuster(minimum: 44.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 86020.9
        )
    }
}
