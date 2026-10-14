import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive accession proposal calculation.
    protocol AdaptiveAccessionProposalAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveAccessionProposal, value: Double) -> Double
    }

    final class TieredAdaptiveAccessionProposalAdjuster: AdaptiveAccessionProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveAccessionProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveAccessionProposalAdjuster: AdaptiveAccessionProposalAdjuster {
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

        func adjust(_ item: AdaptiveAccessionProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveAccessionProposalAdjuster: AdaptiveAccessionProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveAccessionProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveAccessionProposalAdjuster: AdaptiveAccessionProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveAccessionProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive accession proposal steps in order and keeps a trace of each.
    final class AdaptiveAccessionProposalEngine {
        var steps: [any AdaptiveAccessionProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAccessionProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveAccessionProposal) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [AdaptiveAccessionProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAccessionProposalEngine(_ flags: Kit.Flags.Registry) -> AdaptiveAccessionProposalEngine {
        return AdaptiveAccessionProposalEngine(
            steps: [
                TieredAdaptiveAccessionProposalAdjuster(bounds: [3586.0, 7621.0], rates: [0.86, 1.16]),
                FlaggedAdaptiveAccessionProposalAdjuster(
                    flags: flags,
                    flag: "adaptive-accession-proposal-primary",
                    percent: -5.6
                ),
                PercentAdaptiveAccessionProposalAdjuster(percent: 12.0),
                CapAdaptiveAccessionProposalAdjuster(cap: 44655.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 1367.2
        )
    }
}
