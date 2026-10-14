import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality draft calculation.
    protocol CappedModalityDraftModifier {
        func describe() -> String
        func adjust(_ item: CappedModalityDraft, value: Double) -> Double
    }

    final class CappedModalityDraftMaximumOffsetAdjuster: CappedModalityDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CappedModalityDraft, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class FlaggedCappedModalityDraftAdjuster: CappedModalityDraftModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: CappedModalityDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCappedModalityDraftAdjuster: CappedModalityDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedModalityDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityCappedModalityDraftAdjuster: CappedModalityDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CappedModalityDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedModalityDraftAdjuster: CappedModalityDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedModalityDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCappedModalityDraftAdjuster: CappedModalityDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedModalityDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the capped modality draft steps in order and keeps a trace of each.
    final class CappedModalityDraftEngine {
        var steps: [any CappedModalityDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedModalityDraft) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedModalityDraftModifier = steps[index]
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

        func evaluateAll(_ items: [CappedModalityDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedModalityDraftEngine(_ flags: Kit.Flags.Registry) -> CappedModalityDraftEngine {
        return CappedModalityDraftEngine(
            steps: [
                CappedModalityDraftMaximumOffsetAdjuster(weight: 1.88),
                FlaggedCappedModalityDraftAdjuster(flags: flags, flag: "capped-modality-draft-seasonal", percent: 8.0),
                PercentCappedModalityDraftAdjuster(percent: -5.7),
                FacilityCappedModalityDraftAdjuster(factors: ["north": 0.91]),
                MinimumCappedModalityDraftAdjuster(minimum: 16.0),
                CapCappedModalityDraftAdjuster(cap: 2680.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 24888.5
        )
    }
}
