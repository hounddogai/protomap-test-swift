import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted modality proposal calculation.
    protocol WeightedModalityProposalStep {
        func describe() -> String
        func adjust(_ item: WeightedModalityProposal, value: Double) -> Double
    }

    final class WeightedModalityProposalStartsAtOffsetAdjuster: WeightedModalityProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: WeightedModalityProposal, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredWeightedModalityProposalAdjuster: WeightedModalityProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedModalityProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedModalityProposalAdjuster: WeightedModalityProposalStep {
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

        func adjust(_ item: WeightedModalityProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedModalityProposalAdjuster: WeightedModalityProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedModalityProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWeightedModalityProposalAdjuster: WeightedModalityProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedModalityProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted modality proposal steps in order and keeps a trace of each.
    final class WeightedModalityProposalEngine {
        var steps: [any WeightedModalityProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedModalityProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedModalityProposal) -> Double {
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

        func evaluateAll(_ items: [WeightedModalityProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedModalityProposalEngine(_ flags: Kit.Flags.Registry) -> WeightedModalityProposalEngine {
        return WeightedModalityProposalEngine(
            steps: [
                WeightedModalityProposalStartsAtOffsetAdjuster(weight: 1.76),
                TieredWeightedModalityProposalAdjuster(bounds: [3619.0, 8707.0], rates: [1.05, 0.88]),
                FlaggedWeightedModalityProposalAdjuster(
                    flags: flags,
                    flag: "weighted-modality-proposal-pending",
                    percent: -9.8
                ),
                MinimumWeightedModalityProposalAdjuster(minimum: 31.8),
                PercentWeightedModalityProposalAdjuster(percent: 24.4),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 60778.1
        )
    }
}
