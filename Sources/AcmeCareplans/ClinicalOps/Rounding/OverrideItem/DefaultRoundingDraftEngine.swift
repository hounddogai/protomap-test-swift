import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default rounding draft calculation.
    protocol DefaultRoundingDraftAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultRoundingDraft, value: Double) -> Double
    }

    final class RoundingDefaultRoundingDraftAdjuster: DefaultRoundingDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRoundingDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultRoundingDraftAdjuster: DefaultRoundingDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRoundingDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultRoundingDraftAdjuster: DefaultRoundingDraftAdjuster {
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

        func adjust(_ item: DefaultRoundingDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default rounding draft steps in order and keeps a trace of each.
    final class DefaultRoundingDraftEngine {
        var steps: [any DefaultRoundingDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRoundingDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRoundingDraft) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DefaultRoundingDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRoundingDraftEngine(_ flags: Kit.Flags.Registry) -> DefaultRoundingDraftEngine {
        return DefaultRoundingDraftEngine(
            steps: [
                RoundingDefaultRoundingDraftAdjuster(step: 5.0),
                MinimumDefaultRoundingDraftAdjuster(minimum: 42.7),
                FlaggedDefaultRoundingDraftAdjuster(
                    flags: flags,
                    flag: "default-rounding-draft-batched",
                    percent: -5.7
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 34837.6
        )
    }
}
