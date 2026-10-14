import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling closure proposal calculation.
    protocol RollingClosureProposalFactor {
        func describe() -> String
        func adjust(_ item: RollingClosureProposal, value: Double) -> Double
    }

    final class UnitRollingClosureProposalAdjuster: RollingClosureProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RollingClosureProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingClosureProposalAdjuster: RollingClosureProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingClosureProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingClosureProposalAdjuster: RollingClosureProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingClosureProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingClosureProposalRateOffsetAdjuster: RollingClosureProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RollingClosureProposal, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the rolling closure proposal steps in order and keeps a trace of each.
    final class RollingClosureProposalEngine {
        var steps: [any RollingClosureProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClosureProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingClosureProposal) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [RollingClosureProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingClosureProposalEngine() -> RollingClosureProposalEngine {
        return RollingClosureProposalEngine(
            steps: [
                UnitRollingClosureProposalAdjuster(factors: ["north": 1.09]),
                MinimumRollingClosureProposalAdjuster(minimum: 25.3),
                TieredRollingClosureProposalAdjuster(
                    bounds: [2576.0, 3755.0, 3877.0, 4972.0],
                    rates: [0.89, 1.15, 0.97, 0.85]
                ),
                RollingClosureProposalRateOffsetAdjuster(weight: 0.62),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 34702.8
        )
    }
}
