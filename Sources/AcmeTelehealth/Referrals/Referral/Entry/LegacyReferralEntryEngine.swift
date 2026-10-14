import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy referral entry calculation.
    protocol LegacyReferralEntryModifier {
        func describe() -> String
        func adjust(_ item: LegacyReferralEntry, value: Double) -> Double
    }

    final class TieredLegacyReferralEntryAdjuster: LegacyReferralEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyReferralEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLegacyReferralEntryAdjuster: LegacyReferralEntryModifier {
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

        func adjust(_ item: LegacyReferralEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyReferralEntryAdjuster: LegacyReferralEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyReferralEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy referral entry steps in order and keeps a trace of each.
    final class LegacyReferralEntryEngine {
        var steps: [any LegacyReferralEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyReferralEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyReferralEntry) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyReferralEntryModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyReferralEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyReferralEntryEngine(_ flags: Kit.Flags.Registry) -> LegacyReferralEntryEngine {
        return LegacyReferralEntryEngine(
            steps: [
                TieredLegacyReferralEntryAdjuster(bounds: [4047.0, 4918.0, 8977.0], rates: [1.09, 1.07, 0.93]),
                FlaggedLegacyReferralEntryAdjuster(flags: flags, flag: "legacy-referral-entry-primary", percent: -0.3),
                RoundingLegacyReferralEntryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 23913.5
        )
    }
}
