import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary census proposal calculation.
    protocol PrimaryCensusProposalFactor {
        func describe() -> String
        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double
    }

    final class MinimumPrimaryCensusProposalAdjuster: PrimaryCensusProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryCensusProposalAdjuster: PrimaryCensusProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryCensusProposalAdjuster: PrimaryCensusProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryCensusProposalCapacityOffsetAdjuster: PrimaryCensusProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class SegmentPrimaryCensusProposalAdjuster: PrimaryCensusProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryCensusProposalAdjuster: PrimaryCensusProposalFactor {
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

        func adjust(_ item: PrimaryCensusProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary census proposal steps in order and keeps a trace of each.
    final class PrimaryCensusProposalEngine {
        var steps: [any PrimaryCensusProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCensusProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryCensusProposal) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [PrimaryCensusProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryCensusProposalEngine(_ flags: Kit.Flags.Registry) -> PrimaryCensusProposalEngine {
        return PrimaryCensusProposalEngine(
            steps: [
                MinimumPrimaryCensusProposalAdjuster(minimum: 48.8),
                TieredPrimaryCensusProposalAdjuster(
                    bounds: [1676.0, 3077.0, 3724.0, 5600.0],
                    rates: [0.81, 1.1, 1.0, 1.04]
                ),
                PercentPrimaryCensusProposalAdjuster(percent: 19.4),
                PrimaryCensusProposalCapacityOffsetAdjuster(weight: 1.95),
                SegmentPrimaryCensusProposalAdjuster(factors: ["north": 0.76, "retail": 1.11, "west": 0.87]),
                FlaggedPrimaryCensusProposalAdjuster(
                    flags: flags,
                    flag: "primary-census-proposal-tiered",
                    percent: 8.1
                ),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 10696.8
        )
    }
}
