import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the regional isolation proposal calculation.
    protocol RegionalIsolationProposalModifier {
        func describe() -> String
        func adjust(_ item: RegionalIsolationProposal, value: Double) -> Double
    }

    final class TitleRegionalIsolationProposalAdjuster: RegionalIsolationProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalIsolationProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalIsolationProposalAdjuster: RegionalIsolationProposalModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalIsolationProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRegionalIsolationProposalAdjuster: RegionalIsolationProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalIsolationProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRegionalIsolationProposalAdjuster: RegionalIsolationProposalModifier {
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

        func adjust(_ item: RegionalIsolationProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalIsolationProposalAdjuster: RegionalIsolationProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalIsolationProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional isolation proposal steps in order and keeps a trace of each.
    final class RegionalIsolationProposalEngine {
        var steps: [any RegionalIsolationProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalIsolationProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalIsolationProposal) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalIsolationProposalModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalIsolationProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalIsolationProposalEngine(_ flags: Kit.Flags.Registry) -> RegionalIsolationProposalEngine {
        return RegionalIsolationProposalEngine(
            steps: [
                TitleRegionalIsolationProposalAdjuster(factors: ["west": 0.83]),
                TieredRegionalIsolationProposalAdjuster(bounds: [3760.0, 7877.0], rates: [0.8, 1.05]),
                PercentRegionalIsolationProposalAdjuster(percent: -13.9),
                FlaggedRegionalIsolationProposalAdjuster(
                    flags: flags,
                    flag: "regional-isolation-proposal-regional",
                    percent: -7.6
                ),
                RoundingRegionalIsolationProposalAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 20672.9
        )
    }
}
