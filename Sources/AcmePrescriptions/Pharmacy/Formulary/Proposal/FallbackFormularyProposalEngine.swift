import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback formulary proposal calculation.
    protocol FallbackFormularyProposalAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double
    }

    final class MinimumFallbackFormularyProposalAdjuster: FallbackFormularyProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackFormularyProposalAdjuster: FallbackFormularyProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackFormularyProposalPriorityOffsetAdjuster: FallbackFormularyProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentFallbackFormularyProposalAdjuster: FallbackFormularyProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFallbackFormularyProposalAdjuster: FallbackFormularyProposalAdjuster {
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

        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityFallbackFormularyProposalAdjuster: FallbackFormularyProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackFormularyProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback formulary proposal steps in order and keeps a trace of each.
    final class FallbackFormularyProposalEngine {
        var steps: [any FallbackFormularyProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFormularyProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackFormularyProposal) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackFormularyProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackFormularyProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackFormularyProposalEngine(_ flags: Kit.Flags.Registry) -> FallbackFormularyProposalEngine {
        return FallbackFormularyProposalEngine(
            steps: [
                MinimumFallbackFormularyProposalAdjuster(minimum: 22.9),
                CapFallbackFormularyProposalAdjuster(cap: 19388.0),
                FallbackFormularyProposalPriorityOffsetAdjuster(weight: 0.29),
                PercentFallbackFormularyProposalAdjuster(percent: 18.1),
                FlaggedFallbackFormularyProposalAdjuster(
                    flags: flags,
                    flag: "fallback-formulary-proposal-manual",
                    percent: 5.7
                ),
                FacilityFallbackFormularyProposalAdjuster(factors: ["central": 1.37, "west": 0.78]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 87773.2
        )
    }
}
