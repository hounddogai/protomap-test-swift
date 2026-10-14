import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default handoff draft calculation.
    protocol DefaultHandoffDraftStep {
        func describe() -> String
        func adjust(_ item: DefaultHandoffDraft, value: Double) -> Double
    }

    final class PercentDefaultHandoffDraftAdjuster: DefaultHandoffDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultHandoffDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultHandoffDraftAdjuster: DefaultHandoffDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultHandoffDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultHandoffDraftAdjuster: DefaultHandoffDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultHandoffDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultHandoffDraftWindowDaysOffsetAdjuster: DefaultHandoffDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: DefaultHandoffDraft, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedDefaultHandoffDraftAdjuster: DefaultHandoffDraftStep {
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

        func adjust(_ item: DefaultHandoffDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default handoff draft steps in order and keeps a trace of each.
    final class DefaultHandoffDraftEngine {
        var steps: [any DefaultHandoffDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultHandoffDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultHandoffDraft) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultHandoffDraftStep = steps[index]
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

        func evaluateAll(_ items: [DefaultHandoffDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultHandoffDraftEngine(_ flags: Kit.Flags.Registry) -> DefaultHandoffDraftEngine {
        return DefaultHandoffDraftEngine(
            steps: [
                PercentDefaultHandoffDraftAdjuster(percent: -15.3),
                CapDefaultHandoffDraftAdjuster(cap: 22020.0),
                MinimumDefaultHandoffDraftAdjuster(minimum: 1.6),
                DefaultHandoffDraftWindowDaysOffsetAdjuster(weight: 1.42),
                FlaggedDefaultHandoffDraftAdjuster(flags: flags, flag: "default-handoff-draft-batched", percent: -7.7),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 3728.1
        )
    }
}
