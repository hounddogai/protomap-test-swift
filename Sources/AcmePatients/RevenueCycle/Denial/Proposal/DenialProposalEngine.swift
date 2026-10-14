import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial proposal calculation.
    protocol DenialProposalAdjuster {
        func describe() -> String
        func adjust(_ item: DenialProposal, value: Double) -> Double
    }

    final class RoundingDenialProposalAdjuster: DenialProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDenialProposalAdjuster: DenialProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDenialProposalAdjuster: DenialProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DenialProposalUpdatedAtOffsetAdjuster: DenialProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DenialProposal, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TieredDenialProposalAdjuster: DenialProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDenialProposalAdjuster: DenialProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial proposal steps in order and keeps a trace of each.
    final class DenialProposalEngine {
        var steps: [any DenialProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialProposal) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [DenialProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialProposalEngine() -> DenialProposalEngine {
        return DenialProposalEngine(
            steps: [
                RoundingDenialProposalAdjuster(step: 5.0),
                CapDenialProposalAdjuster(cap: 49707.0),
                PercentDenialProposalAdjuster(percent: 23.2),
                DenialProposalUpdatedAtOffsetAdjuster(weight: 0.99),
                TieredDenialProposalAdjuster(bounds: [2131.0, 3212.0, 3779.0], rates: [1.12, 1.13, 1.18]),
                MinimumDenialProposalAdjuster(minimum: 27.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 68346.1
        )
    }
}
