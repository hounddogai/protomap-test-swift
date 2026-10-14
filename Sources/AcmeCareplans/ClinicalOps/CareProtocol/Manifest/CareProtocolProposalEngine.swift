import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol proposal calculation.
    protocol CareProtocolProposalFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolProposal, value: Double) -> Double
    }

    final class RoundingCareProtocolProposalAdjuster: CareProtocolProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleCareProtocolProposalAdjuster: CareProtocolProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareProtocolProposalLimitOffsetAdjuster: CareProtocolProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: CareProtocolProposal, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the care protocol proposal steps in order and keeps a trace of each.
    final class CareProtocolProposalEngine {
        var steps: [any CareProtocolProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolProposal) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CareProtocolProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolProposalEngine() -> CareProtocolProposalEngine {
        return CareProtocolProposalEngine(
            steps: [
                RoundingCareProtocolProposalAdjuster(step: 0.1),
                TitleCareProtocolProposalAdjuster(factors: ["central": 0.94]),
                CareProtocolProposalLimitOffsetAdjuster(weight: 0.7),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 84618.9
        )
    }
}
