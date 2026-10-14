import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling read proposal calculation.
    protocol RollingReadProposalStep {
        func describe() -> String
        func adjust(_ item: RollingReadProposal, value: Double) -> Double
    }

    final class RoundingRollingReadProposalAdjuster: RollingReadProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingReadProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingReadProposalAdjuster: RollingReadProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingReadProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingReadProposalAdjuster: RollingReadProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingReadProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingReadProposalAdjuster: RollingReadProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingReadProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling read proposal steps in order and keeps a trace of each.
    final class RollingReadProposalEngine {
        var steps: [any RollingReadProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingReadProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingReadProposal) -> Double {
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

        func evaluateAll(_ items: [RollingReadProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingReadProposalEngine() -> RollingReadProposalEngine {
        return RollingReadProposalEngine(
            steps: [
                RoundingRollingReadProposalAdjuster(step: 0.1),
                TieredRollingReadProposalAdjuster(bounds: [4111.0, 9786.0, 9957.0], rates: [0.8, 1.16, 1.11]),
                CapRollingReadProposalAdjuster(cap: 26965.0),
                MinimumRollingReadProposalAdjuster(minimum: 25.5),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 50621.0
        )
    }
}
