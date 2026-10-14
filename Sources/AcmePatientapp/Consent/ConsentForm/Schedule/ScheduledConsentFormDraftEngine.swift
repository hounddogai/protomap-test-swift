import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled consent form draft calculation.
    protocol ScheduledConsentFormDraftAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double
    }

    final class RoundingScheduledConsentFormDraftAdjuster: ScheduledConsentFormDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledConsentFormDraftAdjuster: ScheduledConsentFormDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleScheduledConsentFormDraftAdjuster: ScheduledConsentFormDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledConsentFormDraftRateOffsetAdjuster: ScheduledConsentFormDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentScheduledConsentFormDraftAdjuster: ScheduledConsentFormDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedScheduledConsentFormDraftAdjuster: ScheduledConsentFormDraftAdjuster {
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

        func adjust(_ item: ScheduledConsentFormDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled consent form draft steps in order and keeps a trace of each.
    final class ScheduledConsentFormDraftEngine {
        var steps: [any ScheduledConsentFormDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledConsentFormDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledConsentFormDraft) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [ScheduledConsentFormDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledConsentFormDraftEngine(_ flags: Kit.Flags.Registry) -> ScheduledConsentFormDraftEngine {
        return ScheduledConsentFormDraftEngine(
            steps: [
                RoundingScheduledConsentFormDraftAdjuster(step: 5.0),
                CapScheduledConsentFormDraftAdjuster(cap: 41551.0),
                TitleScheduledConsentFormDraftAdjuster(factors: ["central": 1.25]),
                ScheduledConsentFormDraftRateOffsetAdjuster(weight: 0.47),
                PercentScheduledConsentFormDraftAdjuster(percent: -1.4),
                FlaggedScheduledConsentFormDraftAdjuster(
                    flags: flags,
                    flag: "scheduled-consent-form-draft-seasonal",
                    percent: 7.7
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 43367.5
        )
    }
}
