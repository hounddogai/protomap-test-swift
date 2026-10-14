import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered referral template calculation.
    protocol TieredReferralTemplateFactor {
        func describe() -> String
        func adjust(_ item: TieredReferralTemplate, value: Double) -> Double
    }

    final class MinimumTieredReferralTemplateAdjuster: TieredReferralTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReferralTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTieredReferralTemplateAdjuster: TieredReferralTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredReferralTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredReferralTemplateAdjuster: TieredReferralTemplateFactor {
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

        func adjust(_ item: TieredReferralTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered referral template steps in order and keeps a trace of each.
    final class TieredReferralTemplateEngine {
        var steps: [any TieredReferralTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReferralTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredReferralTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredReferralTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [TieredReferralTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredReferralTemplateEngine(_ flags: Kit.Flags.Registry) -> TieredReferralTemplateEngine {
        return TieredReferralTemplateEngine(
            steps: [
                MinimumTieredReferralTemplateAdjuster(minimum: 22.5),
                RoundingTieredReferralTemplateAdjuster(step: 0.05),
                FlaggedTieredReferralTemplateAdjuster(
                    flags: flags,
                    flag: "tiered-referral-template-global",
                    percent: 1.8
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 54845.2
        )
    }
}
