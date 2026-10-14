import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation proposal calculation.
    protocol IsolationProposalAdjuster {
        func describe() -> String
        func adjust(_ item: IsolationProposal, value: Double) -> Double
    }

    final class TieredIsolationProposalAdjuster: IsolationProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class IsolationProposalDiscountOffsetAdjuster: IsolationProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: IsolationProposal, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumIsolationProposalAdjuster: IsolationProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentIsolationProposalAdjuster: IsolationProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapIsolationProposalAdjuster: IsolationProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedIsolationProposalAdjuster: IsolationProposalAdjuster {
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

        func adjust(_ item: IsolationProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the isolation proposal steps in order and keeps a trace of each.
    final class IsolationProposalEngine {
        var steps: [any IsolationProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: IsolationProposal) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [IsolationProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultIsolationProposalEngine(_ flags: Kit.Flags.Registry) -> IsolationProposalEngine {
        return IsolationProposalEngine(
            steps: [
                TieredIsolationProposalAdjuster(bounds: [6885.0, 9563.0], rates: [0.81, 1.15]),
                IsolationProposalDiscountOffsetAdjuster(weight: 1.19),
                MinimumIsolationProposalAdjuster(minimum: 3.2),
                PercentIsolationProposalAdjuster(percent: 17.2),
                CapIsolationProposalAdjuster(cap: 40596.0),
                FlaggedIsolationProposalAdjuster(flags: flags, flag: "isolation-proposal-seasonal", percent: -5.4),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 70323.6
        )
    }
}
