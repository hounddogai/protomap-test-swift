import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer proposal calculation.
    protocol TransferProposalModifier {
        func describe() -> String
        func adjust(_ item: TransferProposal, value: Double) -> Double
    }

    final class CapTransferProposalAdjuster: TransferProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTransferProposalAdjuster: TransferProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTransferProposalAdjuster: TransferProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the transfer proposal steps in order and keeps a trace of each.
    final class TransferProposalEngine {
        var steps: [any TransferProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TransferProposal) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [TransferProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTransferProposalEngine() -> TransferProposalEngine {
        return TransferProposalEngine(
            steps: [
                CapTransferProposalAdjuster(cap: 38097.0),
                PercentTransferProposalAdjuster(percent: -22.1),
                RoundingTransferProposalAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 83785.4
        )
    }
}
