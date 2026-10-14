import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal referral profile calculation.
    protocol SeasonalReferralProfileStep {
        func describe() -> String
        func adjust(_ item: SeasonalReferralProfile, value: Double) -> Double
    }

    final class RoundingSeasonalReferralProfileAdjuster: SeasonalReferralProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalReferralProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalReferralProfileAdjuster: SeasonalReferralProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalReferralProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalReferralProfileWeightOffsetAdjuster: SeasonalReferralProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: SeasonalReferralProfile, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredSeasonalReferralProfileAdjuster: SeasonalReferralProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalReferralProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalReferralProfileAdjuster: SeasonalReferralProfileStep {
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

        func adjust(_ item: SeasonalReferralProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal referral profile steps in order and keeps a trace of each.
    final class SeasonalReferralProfileEngine {
        var steps: [any SeasonalReferralProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReferralProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalReferralProfile) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [SeasonalReferralProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalReferralProfileEngine(_ flags: Kit.Flags.Registry) -> SeasonalReferralProfileEngine {
        return SeasonalReferralProfileEngine(
            steps: [
                RoundingSeasonalReferralProfileAdjuster(step: 0.5),
                PercentSeasonalReferralProfileAdjuster(percent: 5.6),
                SeasonalReferralProfileWeightOffsetAdjuster(weight: 0.04),
                TieredSeasonalReferralProfileAdjuster(
                    bounds: [735.0, 1192.0, 6533.0, 6644.0],
                    rates: [0.82, 1.11, 0.88, 1.02]
                ),
                FlaggedSeasonalReferralProfileAdjuster(
                    flags: flags,
                    flag: "seasonal-referral-profile-regional",
                    percent: -2.0
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 54561.6
        )
    }
}
