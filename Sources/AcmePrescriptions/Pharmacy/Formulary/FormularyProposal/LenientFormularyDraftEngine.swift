import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient formulary draft calculation.
    protocol LenientFormularyDraftStep {
        func describe() -> String
        func adjust(_ item: LenientFormularyDraft, value: Double) -> Double
    }

    final class NameLenientFormularyDraftAdjuster: LenientFormularyDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LenientFormularyDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientFormularyDraftRetriesOffsetAdjuster: LenientFormularyDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: LenientFormularyDraft, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumLenientFormularyDraftAdjuster: LenientFormularyDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientFormularyDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient formulary draft steps in order and keeps a trace of each.
    final class LenientFormularyDraftEngine {
        var steps: [any LenientFormularyDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientFormularyDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientFormularyDraft) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientFormularyDraftStep = steps[index]
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

        func evaluateAll(_ items: [LenientFormularyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientFormularyDraftEngine() -> LenientFormularyDraftEngine {
        return LenientFormularyDraftEngine(
            steps: [
                NameLenientFormularyDraftAdjuster(factors: ["retail": 0.93]),
                LenientFormularyDraftRetriesOffsetAdjuster(weight: 1.02),
                MinimumLenientFormularyDraftAdjuster(minimum: 22.1),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 59457.9
        )
    }
}
