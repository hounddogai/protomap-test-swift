import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive formulary draft calculation.
    protocol AdaptiveFormularyDraftAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double
    }

    final class FlaggedAdaptiveFormularyDraftAdjuster: AdaptiveFormularyDraftAdjuster {
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

        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveFormularyDraftMinimumOffsetAdjuster: AdaptiveFormularyDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumAdaptiveFormularyDraftAdjuster: AdaptiveFormularyDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptiveFormularyDraftAdjuster: AdaptiveFormularyDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAdaptiveFormularyDraftAdjuster: AdaptiveFormularyDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveFormularyDraftAdjuster: AdaptiveFormularyDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveFormularyDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive formulary draft steps in order and keeps a trace of each.
    final class AdaptiveFormularyDraftEngine {
        var steps: [any AdaptiveFormularyDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFormularyDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveFormularyDraft) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AdaptiveFormularyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFormularyDraftEngine(_ flags: Kit.Flags.Registry) -> AdaptiveFormularyDraftEngine {
        return AdaptiveFormularyDraftEngine(
            steps: [
                FlaggedAdaptiveFormularyDraftAdjuster(
                    flags: flags,
                    flag: "adaptive-formulary-draft-regional",
                    percent: -9.3
                ),
                AdaptiveFormularyDraftMinimumOffsetAdjuster(weight: 1.12),
                MinimumAdaptiveFormularyDraftAdjuster(minimum: 8.5),
                PercentAdaptiveFormularyDraftAdjuster(percent: -15.9),
                TitleAdaptiveFormularyDraftAdjuster(factors: ["online": 0.91]),
                RoundingAdaptiveFormularyDraftAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 37260.0
        )
    }
}
