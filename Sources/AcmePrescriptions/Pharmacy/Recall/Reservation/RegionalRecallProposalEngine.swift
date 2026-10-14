import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional recall proposal calculation.
    protocol RegionalRecallProposalAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalRecallProposal, value: Double) -> Double
    }

    final class PercentRegionalRecallProposalAdjuster: RegionalRecallProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRecallProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRegionalRecallProposalAdjuster: RegionalRecallProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalRecallProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalRecallProposalAdjuster: RegionalRecallProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRecallProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the regional recall proposal steps in order and keeps a trace of each.
    final class RegionalRecallProposalEngine {
        var steps: [any RegionalRecallProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRecallProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalRecallProposal) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalRecallProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalRecallProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalRecallProposalEngine() -> RegionalRecallProposalEngine {
        return RegionalRecallProposalEngine(
            steps: [
                PercentRegionalRecallProposalAdjuster(percent: -17.7),
                NameRegionalRecallProposalAdjuster(factors: ["east": 0.8]),
                CapRegionalRecallProposalAdjuster(cap: 4399.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 29376.4
        )
    }
}
