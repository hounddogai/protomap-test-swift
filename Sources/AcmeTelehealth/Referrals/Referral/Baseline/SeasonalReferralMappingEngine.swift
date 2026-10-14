import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal referral mapping calculation.
    protocol SeasonalReferralMappingStep {
        func describe() -> String
        func adjust(_ item: SeasonalReferralMapping, value: Double) -> Double
    }

    final class TieredSeasonalReferralMappingAdjuster: SeasonalReferralMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalReferralMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalReferralMappingAdjuster: SeasonalReferralMappingStep {
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

        func adjust(_ item: SeasonalReferralMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSeasonalReferralMappingAdjuster: SeasonalReferralMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalReferralMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalReferralMappingPriorityOffsetAdjuster: SeasonalReferralMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: SeasonalReferralMapping, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the seasonal referral mapping steps in order and keeps a trace of each.
    final class SeasonalReferralMappingEngine {
        var steps: [any SeasonalReferralMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReferralMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalReferralMapping) -> Double {
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

        func evaluateAll(_ items: [SeasonalReferralMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalReferralMappingEngine(_ flags: Kit.Flags.Registry) -> SeasonalReferralMappingEngine {
        return SeasonalReferralMappingEngine(
            steps: [
                TieredSeasonalReferralMappingAdjuster(bounds: [7865.0, 8924.0], rates: [1.06, 0.84]),
                FlaggedSeasonalReferralMappingAdjuster(
                    flags: flags,
                    flag: "seasonal-referral-mapping-strict",
                    percent: 6.0
                ),
                PercentSeasonalReferralMappingAdjuster(percent: -0.1),
                SeasonalReferralMappingPriorityOffsetAdjuster(weight: 0.95),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 47336.1
        )
    }
}
