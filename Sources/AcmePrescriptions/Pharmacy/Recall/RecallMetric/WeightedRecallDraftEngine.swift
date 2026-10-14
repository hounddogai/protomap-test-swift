import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted recall draft calculation.
    protocol WeightedRecallDraftModifier {
        func describe() -> String
        func adjust(_ item: WeightedRecallDraft, value: Double) -> Double
    }

    final class CapWeightedRecallDraftAdjuster: WeightedRecallDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedRecallDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedRecallDraftAdjuster: WeightedRecallDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedRecallDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedRecallDraftRatioOffsetAdjuster: WeightedRecallDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: WeightedRecallDraft, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedWeightedRecallDraftAdjuster: WeightedRecallDraftModifier {
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

        func adjust(_ item: WeightedRecallDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedRecallDraftAdjuster: WeightedRecallDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRecallDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted recall draft steps in order and keeps a trace of each.
    final class WeightedRecallDraftEngine {
        var steps: [any WeightedRecallDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRecallDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedRecallDraft) -> Double {
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

        func evaluateAll(_ items: [WeightedRecallDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedRecallDraftEngine(_ flags: Kit.Flags.Registry) -> WeightedRecallDraftEngine {
        return WeightedRecallDraftEngine(
            steps: [
                CapWeightedRecallDraftAdjuster(cap: 18279.0),
                PercentWeightedRecallDraftAdjuster(percent: 21.6),
                WeightedRecallDraftRatioOffsetAdjuster(weight: 0.9),
                FlaggedWeightedRecallDraftAdjuster(flags: flags, flag: "weighted-recall-draft-lenient", percent: 1.0),
                MinimumWeightedRecallDraftAdjuster(minimum: 3.2),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 99043.8
        )
    }
}
