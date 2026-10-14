import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy proposal calculation.
    protocol ProxyProposalFactor {
        func describe() -> String
        func adjust(_ item: ProxyProposal, value: Double) -> Double
    }

    final class FlaggedProxyProposalAdjuster: ProxyProposalFactor {
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

        func adjust(_ item: ProxyProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumProxyProposalAdjuster: ProxyProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentProxyProposalAdjuster: ProxyProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityProxyProposalAdjuster: ProxyProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ProxyProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the proxy proposal steps in order and keeps a trace of each.
    final class ProxyProposalEngine {
        var steps: [any ProxyProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyProposal) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [ProxyProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyProposalEngine(_ flags: Kit.Flags.Registry) -> ProxyProposalEngine {
        return ProxyProposalEngine(
            steps: [
                FlaggedProxyProposalAdjuster(flags: flags, flag: "proxy-proposal-manual", percent: -3.1),
                MinimumProxyProposalAdjuster(minimum: 15.5),
                PercentProxyProposalAdjuster(percent: -8.8),
                FacilityProxyProposalAdjuster(factors: ["south": 0.83, "retail": 0.98]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 47697.9
        )
    }
}
