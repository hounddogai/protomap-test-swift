import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap threshold calculation.
    protocol CareGapThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapThreshold, value: Double) -> Double
    }

    final class FlaggedCareGapThresholdAdjuster: CareGapThresholdAdjuster {
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

        func adjust(_ item: CareGapThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareGapThresholdAdjuster: CareGapThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCareGapThresholdAdjuster: CareGapThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCareGapThresholdAdjuster: CareGapThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care gap threshold steps in order and keeps a trace of each.
    final class CareGapThresholdEngine {
        var steps: [any CareGapThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapThreshold) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [CareGapThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapThresholdEngine(_ flags: Kit.Flags.Registry) -> CareGapThresholdEngine {
        return CareGapThresholdEngine(
            steps: [
                FlaggedCareGapThresholdAdjuster(flags: flags, flag: "care-gap-threshold-rolling", percent: 1.4),
                TieredCareGapThresholdAdjuster(bounds: [2695.0, 4623.0, 7086.0], rates: [1.08, 1.14, 1.08]),
                PercentCareGapThresholdAdjuster(percent: 21.8),
                RoundingCareGapThresholdAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 99773.9
        )
    }
}
