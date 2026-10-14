import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled proxy proposal calculation.
    protocol ScheduledProxyProposalAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledProxyProposal, value: Double) -> Double
    }

    final class FlaggedScheduledProxyProposalAdjuster: ScheduledProxyProposalAdjuster {
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

        func adjust(_ item: ScheduledProxyProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledProxyProposalAdjuster: ScheduledProxyProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledProxyProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledProxyProposalVersionOffsetAdjuster: ScheduledProxyProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ScheduledProxyProposal, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class MinimumScheduledProxyProposalAdjuster: ScheduledProxyProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledProxyProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled proxy proposal steps in order and keeps a trace of each.
    final class ScheduledProxyProposalEngine {
        var steps: [any ScheduledProxyProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledProxyProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledProxyProposal) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ScheduledProxyProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledProxyProposalEngine(_ flags: Kit.Flags.Registry) -> ScheduledProxyProposalEngine {
        return ScheduledProxyProposalEngine(
            steps: [
                FlaggedScheduledProxyProposalAdjuster(
                    flags: flags,
                    flag: "scheduled-proxy-proposal-tiered",
                    percent: 9.1
                ),
                TieredScheduledProxyProposalAdjuster(bounds: [1748.0, 1910.0], rates: [1.13, 0.85]),
                ScheduledProxyProposalVersionOffsetAdjuster(weight: 1.27),
                MinimumScheduledProxyProposalAdjuster(minimum: 35.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 50304.5
        )
    }
}
