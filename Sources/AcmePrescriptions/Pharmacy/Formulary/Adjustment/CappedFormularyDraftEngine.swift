import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped formulary draft calculation.
    protocol CappedFormularyDraftFactor {
        func describe() -> String
        func adjust(_ item: CappedFormularyDraft, value: Double) -> Double
    }

    final class RoundingCappedFormularyDraftAdjuster: CappedFormularyDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedFormularyDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCappedFormularyDraftAdjuster: CappedFormularyDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedFormularyDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedFormularyDraftDiscountOffsetAdjuster: CappedFormularyDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: CappedFormularyDraft, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the capped formulary draft steps in order and keeps a trace of each.
    final class CappedFormularyDraftEngine {
        var steps: [any CappedFormularyDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedFormularyDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedFormularyDraft) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedFormularyDraftFactor = steps[index]
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

        func evaluateAll(_ items: [CappedFormularyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedFormularyDraftEngine() -> CappedFormularyDraftEngine {
        return CappedFormularyDraftEngine(
            steps: [
                RoundingCappedFormularyDraftAdjuster(step: 0.05),
                CapCappedFormularyDraftAdjuster(cap: 45282.0),
                CappedFormularyDraftDiscountOffsetAdjuster(weight: 1.66),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 42871.7
        )
    }
}
