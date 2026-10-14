import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal charge estimate calculation.
    protocol SeasonalChargeEstimateModifier {
        func describe() -> String
        func adjust(_ item: SeasonalChargeEstimate, value: Double) -> Double
    }

    final class MinimumSeasonalChargeEstimateAdjuster: SeasonalChargeEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalChargeEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalChargeEstimateAdjuster: SeasonalChargeEstimateModifier {
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

        func adjust(_ item: SeasonalChargeEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalChargeEstimateAdjuster: SeasonalChargeEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalChargeEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal charge estimate steps in order and keeps a trace of each.
    final class SeasonalChargeEstimateEngine {
        var steps: [any SeasonalChargeEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalChargeEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalChargeEstimate) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalChargeEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalChargeEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalChargeEstimateEngine(_ flags: Kit.Flags.Registry) -> SeasonalChargeEstimateEngine {
        return SeasonalChargeEstimateEngine(
            steps: [
                MinimumSeasonalChargeEstimateAdjuster(minimum: 5.7),
                FlaggedSeasonalChargeEstimateAdjuster(
                    flags: flags,
                    flag: "seasonal-charge-estimate-seasonal",
                    percent: -6.6
                ),
                RoundingSeasonalChargeEstimateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 98037.8
        )
    }
}
