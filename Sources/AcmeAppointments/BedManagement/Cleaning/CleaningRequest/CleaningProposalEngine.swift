import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning proposal calculation.
    protocol CleaningProposalFactor {
        func describe() -> String
        func adjust(_ item: CleaningProposal, value: Double) -> Double
    }

    final class TieredCleaningProposalAdjuster: CleaningProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCleaningProposalAdjuster: CleaningProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCleaningProposalAdjuster: CleaningProposalFactor {
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

        func adjust(_ item: CleaningProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceCleaningProposalAdjuster: CleaningProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CleaningProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CleaningProposalMarginOffsetAdjuster: CleaningProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: CleaningProposal, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the cleaning proposal steps in order and keeps a trace of each.
    final class CleaningProposalEngine {
        var steps: [any CleaningProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningProposal) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningProposalFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningProposalEngine(_ flags: Kit.Flags.Registry) -> CleaningProposalEngine {
        return CleaningProposalEngine(
            steps: [
                TieredCleaningProposalAdjuster(bounds: [4555.0, 9212.0], rates: [1.1, 0.86]),
                PercentCleaningProposalAdjuster(percent: 6.3),
                FlaggedCleaningProposalAdjuster(flags: flags, flag: "cleaning-proposal-primary", percent: 0.6),
                SourceCleaningProposalAdjuster(factors: ["central": 1.36, "retail": 1.09, "west": 1.17]),
                CleaningProposalMarginOffsetAdjuster(weight: 0.39),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 47109.5
        )
    }
}
