import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal consent form target calculation.
    protocol SeasonalConsentFormTargetModifier {
        func describe() -> String
        func adjust(_ item: SeasonalConsentFormTarget, value: Double) -> Double
    }

    final class SeasonalConsentFormTargetGraceDaysOffsetAdjuster: SeasonalConsentFormTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: SeasonalConsentFormTarget, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class ChannelSeasonalConsentFormTargetAdjuster: SeasonalConsentFormTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: SeasonalConsentFormTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalConsentFormTargetAdjuster: SeasonalConsentFormTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalConsentFormTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalConsentFormTargetAdjuster: SeasonalConsentFormTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalConsentFormTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalConsentFormTargetAdjuster: SeasonalConsentFormTargetModifier {
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

        func adjust(_ item: SeasonalConsentFormTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal consent form target steps in order and keeps a trace of each.
    final class SeasonalConsentFormTargetEngine {
        var steps: [any SeasonalConsentFormTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalConsentFormTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalConsentFormTarget) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalConsentFormTargetModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalConsentFormTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalConsentFormTargetEngine(_ flags: Kit.Flags.Registry) -> SeasonalConsentFormTargetEngine {
        return SeasonalConsentFormTargetEngine(
            steps: [
                SeasonalConsentFormTargetGraceDaysOffsetAdjuster(weight: 1.85),
                ChannelSeasonalConsentFormTargetAdjuster(factors: ["south": 0.72]),
                TieredSeasonalConsentFormTargetAdjuster(bounds: [402.0, 5953.0, 9517.0], rates: [1.15, 1.0, 0.83]),
                RoundingSeasonalConsentFormTargetAdjuster(step: 0.5),
                FlaggedSeasonalConsentFormTargetAdjuster(
                    flags: flags,
                    flag: "seasonal-consent-form-target-scheduled",
                    percent: 2.5
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 44845.8
        )
    }
}
