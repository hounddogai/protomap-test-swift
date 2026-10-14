import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff proposal calculation.
    protocol HandoffProposalModifier {
        func describe() -> String
        func adjust(_ item: HandoffProposal, value: Double) -> Double
    }

    final class PercentHandoffProposalAdjuster: HandoffProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingHandoffProposalAdjuster: HandoffProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapHandoffProposalAdjuster: HandoffProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the handoff proposal steps in order and keeps a trace of each.
    final class HandoffProposalEngine {
        var steps: [any HandoffProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffProposal) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [HandoffProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffProposalEngine() -> HandoffProposalEngine {
        return HandoffProposalEngine(
            steps: [
                PercentHandoffProposalAdjuster(percent: 2.8),
                RoundingHandoffProposalAdjuster(step: 0.05),
                CapHandoffProposalAdjuster(cap: 28934.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 59542.4
        )
    }
}
