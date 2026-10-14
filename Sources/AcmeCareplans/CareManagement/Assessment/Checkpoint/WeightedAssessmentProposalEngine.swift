import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted assessment proposal calculation.
    protocol WeightedAssessmentProposalAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double
    }

    final class MinimumWeightedAssessmentProposalAdjuster: WeightedAssessmentProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedAssessmentProposalWeightOffsetAdjuster: WeightedAssessmentProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class FlaggedWeightedAssessmentProposalAdjuster: WeightedAssessmentProposalAdjuster {
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

        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelWeightedAssessmentProposalAdjuster: WeightedAssessmentProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedAssessmentProposalAdjuster: WeightedAssessmentProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedAssessmentProposalAdjuster: WeightedAssessmentProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedAssessmentProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted assessment proposal steps in order and keeps a trace of each.
    final class WeightedAssessmentProposalEngine {
        var steps: [any WeightedAssessmentProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAssessmentProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedAssessmentProposal) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [WeightedAssessmentProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedAssessmentProposalEngine(_ flags: Kit.Flags.Registry) -> WeightedAssessmentProposalEngine {
        return WeightedAssessmentProposalEngine(
            steps: [
                MinimumWeightedAssessmentProposalAdjuster(minimum: 26.8),
                WeightedAssessmentProposalWeightOffsetAdjuster(weight: 0.66),
                FlaggedWeightedAssessmentProposalAdjuster(
                    flags: flags,
                    flag: "weighted-assessment-proposal-fallback",
                    percent: 7.7
                ),
                LabelWeightedAssessmentProposalAdjuster(factors: ["online": 1.09]),
                TieredWeightedAssessmentProposalAdjuster(bounds: [7568.0, 8063.0, 8978.0], rates: [1.03, 0.9, 1.04]),
                CapWeightedAssessmentProposalAdjuster(cap: 21263.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 71530.3
        )
    }
}
