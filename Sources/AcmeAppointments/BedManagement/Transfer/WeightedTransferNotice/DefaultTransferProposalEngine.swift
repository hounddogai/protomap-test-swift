import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default transfer proposal calculation.
    protocol DefaultTransferProposalAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultTransferProposal, value: Double) -> Double
    }

    final class CapDefaultTransferProposalAdjuster: DefaultTransferProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultTransferProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultTransferProposalAdjuster: DefaultTransferProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultTransferProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDefaultTransferProposalAdjuster: DefaultTransferProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultTransferProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultTransferProposalAdjuster: DefaultTransferProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultTransferProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default transfer proposal steps in order and keeps a trace of each.
    final class DefaultTransferProposalEngine {
        var steps: [any DefaultTransferProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultTransferProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultTransferProposal) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultTransferProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultTransferProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultTransferProposalEngine() -> DefaultTransferProposalEngine {
        return DefaultTransferProposalEngine(
            steps: [
                CapDefaultTransferProposalAdjuster(cap: 42706.0),
                MinimumDefaultTransferProposalAdjuster(minimum: 31.9),
                PercentDefaultTransferProposalAdjuster(percent: -2.6),
                RoundingDefaultTransferProposalAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 41688.7
        )
    }
}
