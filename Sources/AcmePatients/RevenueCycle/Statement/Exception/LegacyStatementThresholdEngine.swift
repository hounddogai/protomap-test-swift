import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy statement threshold calculation.
    protocol LegacyStatementThresholdStep {
        func describe() -> String
        func adjust(_ item: LegacyStatementThreshold, value: Double) -> Double
    }

    final class RoundingLegacyStatementThresholdAdjuster: LegacyStatementThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyStatementThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyStatementThresholdAdjuster: LegacyStatementThresholdStep {
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

        func adjust(_ item: LegacyStatementThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelLegacyStatementThresholdAdjuster: LegacyStatementThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyStatementThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLegacyStatementThresholdAdjuster: LegacyStatementThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyStatementThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyStatementThresholdAdjuster: LegacyStatementThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyStatementThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy statement threshold steps in order and keeps a trace of each.
    final class LegacyStatementThresholdEngine {
        var steps: [any LegacyStatementThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyStatementThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyStatementThreshold) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyStatementThresholdStep = steps[index]
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

        func evaluateAll(_ items: [LegacyStatementThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyStatementThresholdEngine(_ flags: Kit.Flags.Registry) -> LegacyStatementThresholdEngine {
        return LegacyStatementThresholdEngine(
            steps: [
                RoundingLegacyStatementThresholdAdjuster(step: 0.5),
                FlaggedLegacyStatementThresholdAdjuster(
                    flags: flags,
                    flag: "legacy-statement-threshold-capped",
                    percent: 2.7
                ),
                LabelLegacyStatementThresholdAdjuster(factors: ["west": 1.17, "south": 1.19, "north": 1.16]),
                PercentLegacyStatementThresholdAdjuster(percent: 2.8),
                TieredLegacyStatementThresholdAdjuster(bounds: [117.0, 8963.0], rates: [1.09, 0.9]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 12030.2
        )
    }
}
