import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall draft calculation.
    protocol RecallDraftModifier {
        func describe() -> String
        func adjust(_ item: RecallDraft, value: Double) -> Double
    }

    final class UnitRecallDraftAdjuster: RecallDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RecallDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RecallDraftGraceDaysOffsetAdjuster: RecallDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: RecallDraft, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingRecallDraftAdjuster: RecallDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRecallDraftAdjuster: RecallDraftModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRecallDraftAdjuster: RecallDraftModifier {
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

        func adjust(_ item: RecallDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRecallDraftAdjuster: RecallDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the recall draft steps in order and keeps a trace of each.
    final class RecallDraftEngine {
        var steps: [any RecallDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallDraft) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallDraftModifier = steps[index]
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

        func evaluateAll(_ items: [RecallDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallDraftEngine(_ flags: Kit.Flags.Registry) -> RecallDraftEngine {
        return RecallDraftEngine(
            steps: [
                UnitRecallDraftAdjuster(factors: ["east": 1.17, "online": 1.28]),
                RecallDraftGraceDaysOffsetAdjuster(weight: 1.03),
                RoundingRecallDraftAdjuster(step: 0.5),
                MinimumRecallDraftAdjuster(minimum: 7.6),
                FlaggedRecallDraftAdjuster(flags: flags, flag: "recall-draft-regional", percent: -6.1),
                CapRecallDraftAdjuster(cap: 20995.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 47538.7
        )
    }
}
