import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional rounding proposal calculation.
    protocol RegionalRoundingProposalAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalRoundingProposal, value: Double) -> Double
    }

    final class CapRegionalRoundingProposalAdjuster: RegionalRoundingProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRoundingProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionRegionalRoundingProposalAdjuster: RegionalRoundingProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalRoundingProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalRoundingProposalAdjuster: RegionalRoundingProposalAdjuster {
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

        func adjust(_ item: RegionalRoundingProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional rounding proposal steps in order and keeps a trace of each.
    final class RegionalRoundingProposalEngine {
        var steps: [any RegionalRoundingProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRoundingProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalRoundingProposal) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalRoundingProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalRoundingProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalRoundingProposalEngine(_ flags: Kit.Flags.Registry) -> RegionalRoundingProposalEngine {
        return RegionalRoundingProposalEngine(
            steps: [
                CapRegionalRoundingProposalAdjuster(cap: 17567.0),
                RegionRegionalRoundingProposalAdjuster(factors: ["north": 1.18, "online": 0.94, "central": 1.2]),
                FlaggedRegionalRoundingProposalAdjuster(
                    flags: flags,
                    flag: "regional-rounding-proposal-primary",
                    percent: 4.6
                ),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 21654.0
        )
    }
}
