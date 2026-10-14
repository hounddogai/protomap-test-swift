import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary proposal calculation.
    protocol FormularyProposalFactor {
        func describe() -> String
        func adjust(_ item: FormularyProposal, value: Double) -> Double
    }

    final class PercentFormularyProposalAdjuster: FormularyProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentFormularyProposalAdjuster: FormularyProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FormularyProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFormularyProposalAdjuster: FormularyProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the formulary proposal steps in order and keeps a trace of each.
    final class FormularyProposalEngine {
        var steps: [any FormularyProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularyProposal) -> Double {
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

        func evaluateAll(_ items: [FormularyProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularyProposalEngine() -> FormularyProposalEngine {
        return FormularyProposalEngine(
            steps: [
                PercentFormularyProposalAdjuster(percent: 6.5),
                SegmentFormularyProposalAdjuster(factors: ["south": 1.12]),
                CapFormularyProposalAdjuster(cap: 20722.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 34133.2
        )
    }
}
