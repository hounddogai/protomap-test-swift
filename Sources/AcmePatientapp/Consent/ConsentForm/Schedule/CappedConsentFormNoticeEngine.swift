import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped consent form notice calculation.
    protocol CappedConsentFormNoticeStep {
        func describe() -> String
        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double
    }

    final class FlaggedCappedConsentFormNoticeAdjuster: CappedConsentFormNoticeStep {
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

        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedConsentFormNoticeAdjuster: CappedConsentFormNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCappedConsentFormNoticeAdjuster: CappedConsentFormNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedConsentFormNoticeAdjuster: CappedConsentFormNoticeStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedConsentFormNoticeAdjuster: CappedConsentFormNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceCappedConsentFormNoticeAdjuster: CappedConsentFormNoticeStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CappedConsentFormNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped consent form notice steps in order and keeps a trace of each.
    final class CappedConsentFormNoticeEngine {
        var steps: [any CappedConsentFormNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedConsentFormNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedConsentFormNotice) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedConsentFormNoticeStep = steps[index]
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

        func evaluateAll(_ items: [CappedConsentFormNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedConsentFormNoticeEngine(_ flags: Kit.Flags.Registry) -> CappedConsentFormNoticeEngine {
        return CappedConsentFormNoticeEngine(
            steps: [
                FlaggedCappedConsentFormNoticeAdjuster(
                    flags: flags,
                    flag: "capped-consent-form-notice-weighted",
                    percent: 4.1
                ),
                RoundingCappedConsentFormNoticeAdjuster(step: 1.0),
                MinimumCappedConsentFormNoticeAdjuster(minimum: 5.2),
                PercentCappedConsentFormNoticeAdjuster(percent: 22.3),
                CapCappedConsentFormNoticeAdjuster(cap: 42554.0),
                SourceCappedConsentFormNoticeAdjuster(factors: ["south": 0.83]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 8612.7
        )
    }
}
