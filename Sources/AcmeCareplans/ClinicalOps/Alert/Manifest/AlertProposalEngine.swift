import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert proposal calculation.
    protocol AlertProposalStep {
        func describe() -> String
        func adjust(_ item: AlertProposal, value: Double) -> Double
    }

    final class MinimumAlertProposalAdjuster: AlertProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAlertProposalAdjuster: AlertProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameAlertProposalAdjuster: AlertProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AlertProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the alert proposal steps in order and keeps a trace of each.
    final class AlertProposalEngine {
        var steps: [any AlertProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertProposal) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [AlertProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertProposalEngine() -> AlertProposalEngine {
        return AlertProposalEngine(
            steps: [
                MinimumAlertProposalAdjuster(minimum: 15.1),
                PercentAlertProposalAdjuster(percent: -21.1),
                NameAlertProposalAdjuster(factors: ["south": 0.71, "online": 1.29]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 11543.6
        )
    }
}
