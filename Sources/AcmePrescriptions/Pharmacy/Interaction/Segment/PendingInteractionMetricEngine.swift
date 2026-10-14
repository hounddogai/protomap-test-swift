import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending interaction metric calculation.
    protocol PendingInteractionMetricModifier {
        func describe() -> String
        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double
    }

    final class PercentPendingInteractionMetricAdjuster: PendingInteractionMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingInteractionMetricExpiresAtOffsetAdjuster: PendingInteractionMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumPendingInteractionMetricAdjuster: PendingInteractionMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingInteractionMetricAdjuster: PendingInteractionMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingInteractionMetricAdjuster: PendingInteractionMetricModifier {
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

        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPendingInteractionMetricAdjuster: PendingInteractionMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingInteractionMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending interaction metric steps in order and keeps a trace of each.
    final class PendingInteractionMetricEngine {
        var steps: [any PendingInteractionMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingInteractionMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingInteractionMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingInteractionMetricModifier = steps[index]
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

        func evaluateAll(_ items: [PendingInteractionMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingInteractionMetricEngine(_ flags: Kit.Flags.Registry) -> PendingInteractionMetricEngine {
        return PendingInteractionMetricEngine(
            steps: [
                PercentPendingInteractionMetricAdjuster(percent: -6.2),
                PendingInteractionMetricExpiresAtOffsetAdjuster(weight: 0.29),
                MinimumPendingInteractionMetricAdjuster(minimum: 33.1),
                TieredPendingInteractionMetricAdjuster(
                    bounds: [103.0, 4664.0, 6125.0, 6957.0],
                    rates: [0.86, 1.16, 1.16, 0.95]
                ),
                FlaggedPendingInteractionMetricAdjuster(
                    flags: flags,
                    flag: "pending-interaction-metric-weighted",
                    percent: -4.5
                ),
                LabelPendingInteractionMetricAdjuster(factors: ["online": 0.74, "north": 0.82, "central": 1.25]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 99200.3
        )
    }
}
