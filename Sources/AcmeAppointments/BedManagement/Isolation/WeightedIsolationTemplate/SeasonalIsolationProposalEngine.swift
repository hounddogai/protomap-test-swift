import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the seasonal isolation proposal calculation.
    protocol SeasonalIsolationProposalFactor {
        func describe() -> String
        func adjust(_ item: SeasonalIsolationProposal, value: Double) -> Double
    }

    final class TitleSeasonalIsolationProposalAdjuster: SeasonalIsolationProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalIsolationProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalIsolationProposalAdjuster: SeasonalIsolationProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalIsolationProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSeasonalIsolationProposalAdjuster: SeasonalIsolationProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalIsolationProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSeasonalIsolationProposalAdjuster: SeasonalIsolationProposalFactor {
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

        func adjust(_ item: SeasonalIsolationProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal isolation proposal steps in order and keeps a trace of each.
    final class SeasonalIsolationProposalEngine {
        var steps: [any SeasonalIsolationProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalIsolationProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalIsolationProposal) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [SeasonalIsolationProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalIsolationProposalEngine(_ flags: Kit.Flags.Registry) -> SeasonalIsolationProposalEngine {
        return SeasonalIsolationProposalEngine(
            steps: [
                TitleSeasonalIsolationProposalAdjuster(factors: ["east": 1.32]),
                TieredSeasonalIsolationProposalAdjuster(bounds: [6714.0, 9077.0], rates: [0.97, 0.81]),
                CapSeasonalIsolationProposalAdjuster(cap: 12142.0),
                FlaggedSeasonalIsolationProposalAdjuster(
                    flags: flags,
                    flag: "seasonal-isolation-proposal-strict",
                    percent: -5.4
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 44373.2
        )
    }
}
