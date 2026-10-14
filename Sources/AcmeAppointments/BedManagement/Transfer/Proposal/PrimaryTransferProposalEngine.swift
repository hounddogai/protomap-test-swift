import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary transfer proposal calculation.
    protocol PrimaryTransferProposalModifier {
        func describe() -> String
        func adjust(_ item: PrimaryTransferProposal, value: Double) -> Double
    }

    final class CapPrimaryTransferProposalAdjuster: PrimaryTransferProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryTransferProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryTransferProposalAdjuster: PrimaryTransferProposalModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryTransferProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryTransferProposalAdjuster: PrimaryTransferProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryTransferProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryTransferProposalAdjuster: PrimaryTransferProposalModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryTransferProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary transfer proposal steps in order and keeps a trace of each.
    final class PrimaryTransferProposalEngine {
        var steps: [any PrimaryTransferProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryTransferProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryTransferProposal) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PrimaryTransferProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryTransferProposalEngine() -> PrimaryTransferProposalEngine {
        return PrimaryTransferProposalEngine(
            steps: [
                CapPrimaryTransferProposalAdjuster(cap: 31107.0),
                MinimumPrimaryTransferProposalAdjuster(minimum: 37.7),
                PercentPrimaryTransferProposalAdjuster(percent: -5.3),
                TieredPrimaryTransferProposalAdjuster(
                    bounds: [2965.0, 3704.0, 4467.0, 5481.0],
                    rates: [1.01, 1.06, 0.98, 1.19]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 83224.8
        )
    }
}
