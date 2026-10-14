import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted acuity plan proposal calculation.
    protocol WeightedAcuityPlanProposalStep {
        func describe() -> String
        func adjust(_ item: WeightedAcuityPlanProposal, value: Double) -> Double
    }

    final class RoundingWeightedAcuityPlanProposalAdjuster: WeightedAcuityPlanProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedAcuityPlanProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedAcuityPlanProposalAdjuster: WeightedAcuityPlanProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedAcuityPlanProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedAcuityPlanProposalFloorValueOffsetAdjuster: WeightedAcuityPlanProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: WeightedAcuityPlanProposal, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class UnitWeightedAcuityPlanProposalAdjuster: WeightedAcuityPlanProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: WeightedAcuityPlanProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedAcuityPlanProposalAdjuster: WeightedAcuityPlanProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedAcuityPlanProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted acuity plan proposal steps in order and keeps a trace of each.
    final class WeightedAcuityPlanProposalEngine {
        var steps: [any WeightedAcuityPlanProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAcuityPlanProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedAcuityPlanProposal) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [WeightedAcuityPlanProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedAcuityPlanProposalEngine() -> WeightedAcuityPlanProposalEngine {
        return WeightedAcuityPlanProposalEngine(
            steps: [
                RoundingWeightedAcuityPlanProposalAdjuster(step: 5.0),
                CapWeightedAcuityPlanProposalAdjuster(cap: 43977.0),
                WeightedAcuityPlanProposalFloorValueOffsetAdjuster(weight: 1.22),
                UnitWeightedAcuityPlanProposalAdjuster(factors: ["online": 0.82, "retail": 1.34, "west": 1.06]),
                PercentWeightedAcuityPlanProposalAdjuster(percent: 20.4),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 89998.7
        )
    }
}
