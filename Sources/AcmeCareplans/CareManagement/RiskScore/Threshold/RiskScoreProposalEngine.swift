import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score proposal calculation.
    protocol RiskScoreProposalModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreProposal, value: Double) -> Double
    }

    final class MinimumRiskScoreProposalAdjuster: RiskScoreProposalModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRiskScoreProposalAdjuster: RiskScoreProposalModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RiskScoreProposalRatioOffsetAdjuster: RiskScoreProposalModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: RiskScoreProposal, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapRiskScoreProposalAdjuster: RiskScoreProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRiskScoreProposalAdjuster: RiskScoreProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the risk score proposal steps in order and keeps a trace of each.
    final class RiskScoreProposalEngine {
        var steps: [any RiskScoreProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RiskScoreProposal) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [RiskScoreProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRiskScoreProposalEngine() -> RiskScoreProposalEngine {
        return RiskScoreProposalEngine(
            steps: [
                MinimumRiskScoreProposalAdjuster(minimum: 24.5),
                TieredRiskScoreProposalAdjuster(bounds: [1150.0, 5230.0, 6027.0], rates: [1.0, 1.2, 0.84]),
                RiskScoreProposalRatioOffsetAdjuster(weight: 1.75),
                CapRiskScoreProposalAdjuster(cap: 7783.0),
                RoundingRiskScoreProposalAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 35946.0
        )
    }
}
