import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy study proposal calculation.
    protocol LegacyStudyProposalFactor {
        func describe() -> String
        func adjust(_ item: LegacyStudyProposal, value: Double) -> Double
    }

    final class PercentLegacyStudyProposalAdjuster: LegacyStudyProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyStudyProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyStudyProposalScoreOffsetAdjuster: LegacyStudyProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LegacyStudyProposal, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingLegacyStudyProposalAdjuster: LegacyStudyProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyStudyProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyStudyProposalAdjuster: LegacyStudyProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyStudyProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy study proposal steps in order and keeps a trace of each.
    final class LegacyStudyProposalEngine {
        var steps: [any LegacyStudyProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyStudyProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyStudyProposal) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [LegacyStudyProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyStudyProposalEngine() -> LegacyStudyProposalEngine {
        return LegacyStudyProposalEngine(
            steps: [
                PercentLegacyStudyProposalAdjuster(percent: 7.7),
                LegacyStudyProposalScoreOffsetAdjuster(weight: 1.07),
                RoundingLegacyStudyProposalAdjuster(step: 1.0),
                CapLegacyStudyProposalAdjuster(cap: 41074.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 71323.1
        )
    }
}
