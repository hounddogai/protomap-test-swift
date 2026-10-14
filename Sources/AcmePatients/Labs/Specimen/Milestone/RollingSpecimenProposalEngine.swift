import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling specimen proposal calculation.
    protocol RollingSpecimenProposalAdjuster {
        func describe() -> String
        func adjust(_ item: RollingSpecimenProposal, value: Double) -> Double
    }

    final class PercentRollingSpecimenProposalAdjuster: RollingSpecimenProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingSpecimenProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelRollingSpecimenProposalAdjuster: RollingSpecimenProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RollingSpecimenProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingSpecimenProposalAdjuster: RollingSpecimenProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingSpecimenProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling specimen proposal steps in order and keeps a trace of each.
    final class RollingSpecimenProposalEngine {
        var steps: [any RollingSpecimenProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSpecimenProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingSpecimenProposal) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingSpecimenProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingSpecimenProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingSpecimenProposalEngine() -> RollingSpecimenProposalEngine {
        return RollingSpecimenProposalEngine(
            steps: [
                PercentRollingSpecimenProposalAdjuster(percent: -7.7),
                ChannelRollingSpecimenProposalAdjuster(factors: ["south": 0.97, "east": 0.96]),
                TieredRollingSpecimenProposalAdjuster(bounds: [4423.0, 7707.0, 9065.0], rates: [1.04, 1.18, 0.92]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 99346.1
        )
    }
}
