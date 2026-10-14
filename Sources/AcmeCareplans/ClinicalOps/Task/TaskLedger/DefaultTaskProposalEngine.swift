import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default task proposal calculation.
    protocol DefaultTaskProposalAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultTaskProposal, value: Double) -> Double
    }

    final class PercentDefaultTaskProposalAdjuster: DefaultTaskProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultTaskProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultTaskProposalAdjuster: DefaultTaskProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultTaskProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultTaskProposalAdjuster: DefaultTaskProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultTaskProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default task proposal steps in order and keeps a trace of each.
    final class DefaultTaskProposalEngine {
        var steps: [any DefaultTaskProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultTaskProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultTaskProposal) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultTaskProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultTaskProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultTaskProposalEngine() -> DefaultTaskProposalEngine {
        return DefaultTaskProposalEngine(
            steps: [
                PercentDefaultTaskProposalAdjuster(percent: 20.1),
                TieredDefaultTaskProposalAdjuster(bounds: [1776.0, 2783.0, 7598.0], rates: [1.1, 1.03, 0.98]),
                RoundingDefaultTaskProposalAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 60424.7
        )
    }
}
