import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall proposal calculation.
    protocol RecallProposalFactor {
        func describe() -> String
        func adjust(_ item: RecallProposal, value: Double) -> Double
    }

    final class RoundingRecallProposalAdjuster: RecallProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRecallProposalAdjuster: RecallProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RecallProposalMarginOffsetAdjuster: RecallProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: RecallProposal, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class ChannelRecallProposalAdjuster: RecallProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RecallProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRecallProposalAdjuster: RecallProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRecallProposalAdjuster: RecallProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the recall proposal steps in order and keeps a trace of each.
    final class RecallProposalEngine {
        var steps: [any RecallProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RecallProposal) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallProposalFactor = steps[index]
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

        func evaluateAll(_ items: [RecallProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRecallProposalEngine() -> RecallProposalEngine {
        return RecallProposalEngine(
            steps: [
                RoundingRecallProposalAdjuster(step: 1.0),
                PercentRecallProposalAdjuster(percent: -6.5),
                RecallProposalMarginOffsetAdjuster(weight: 1.55),
                ChannelRecallProposalAdjuster(factors: ["west": 1.25, "east": 0.72, "south": 1.28]),
                CapRecallProposalAdjuster(cap: 15975.0),
                TieredRecallProposalAdjuster(
                    bounds: [4200.0, 5169.0, 6561.0, 8681.0],
                    rates: [0.99, 0.94, 0.94, 1.16]
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 59434.2
        )
    }
}
