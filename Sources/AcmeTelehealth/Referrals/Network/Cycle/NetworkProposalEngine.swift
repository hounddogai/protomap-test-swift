import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network proposal calculation.
    protocol NetworkProposalAdjuster {
        func describe() -> String
        func adjust(_ item: NetworkProposal, value: Double) -> Double
    }

    final class FlaggedNetworkProposalAdjuster: NetworkProposalAdjuster {
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

        func adjust(_ item: NetworkProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapNetworkProposalAdjuster: NetworkProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumNetworkProposalAdjuster: NetworkProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredNetworkProposalAdjuster: NetworkProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NetworkProposalVisitMinutesOffsetAdjuster: NetworkProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: NetworkProposal, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the network proposal steps in order and keeps a trace of each.
    final class NetworkProposalEngine {
        var steps: [any NetworkProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkProposal) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [NetworkProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkProposalEngine(_ flags: Kit.Flags.Registry) -> NetworkProposalEngine {
        return NetworkProposalEngine(
            steps: [
                FlaggedNetworkProposalAdjuster(flags: flags, flag: "network-proposal-capped", percent: 4.6),
                CapNetworkProposalAdjuster(cap: 11590.0),
                MinimumNetworkProposalAdjuster(minimum: 6.4),
                TieredNetworkProposalAdjuster(bounds: [616.0, 1404.0, 6992.0], rates: [0.96, 1.01, 1.08]),
                NetworkProposalVisitMinutesOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 77453.3
        )
    }
}
