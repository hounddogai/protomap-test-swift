import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal credential target calculation.
    protocol SeasonalCredentialTargetStep {
        func describe() -> String
        func adjust(_ item: SeasonalCredentialTarget, value: Double) -> Double
    }

    final class FlaggedSeasonalCredentialTargetAdjuster: SeasonalCredentialTargetStep {
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

        func adjust(_ item: SeasonalCredentialTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameSeasonalCredentialTargetAdjuster: SeasonalCredentialTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalCredentialTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalCredentialTargetAdjuster: SeasonalCredentialTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCredentialTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalCredentialTargetAdjuster: SeasonalCredentialTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalCredentialTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal credential target steps in order and keeps a trace of each.
    final class SeasonalCredentialTargetEngine {
        var steps: [any SeasonalCredentialTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCredentialTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalCredentialTarget) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCredentialTargetStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalCredentialTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalCredentialTargetEngine(_ flags: Kit.Flags.Registry) -> SeasonalCredentialTargetEngine {
        return SeasonalCredentialTargetEngine(
            steps: [
                FlaggedSeasonalCredentialTargetAdjuster(
                    flags: flags,
                    flag: "seasonal-credential-target-pending",
                    percent: -7.2
                ),
                NameSeasonalCredentialTargetAdjuster(factors: ["online": 1.09]),
                TieredSeasonalCredentialTargetAdjuster(
                    bounds: [457.0, 6895.0, 7124.0, 8248.0],
                    rates: [1.14, 1.12, 1.1, 1.01]
                ),
                RoundingSeasonalCredentialTargetAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 66586.8
        )
    }
}
