import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled proxy batch calculation.
    protocol ScheduledProxyBatchModifier {
        func describe() -> String
        func adjust(_ item: ScheduledProxyBatch, value: Double) -> Double
    }

    final class CountryScheduledProxyBatchAdjuster: ScheduledProxyBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ScheduledProxyBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledProxyBatchAdjuster: ScheduledProxyBatchModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledProxyBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScheduledProxyBatchAdjuster: ScheduledProxyBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledProxyBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredScheduledProxyBatchAdjuster: ScheduledProxyBatchModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledProxyBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedScheduledProxyBatchAdjuster: ScheduledProxyBatchModifier {
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

        func adjust(_ item: ScheduledProxyBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled proxy batch steps in order and keeps a trace of each.
    final class ScheduledProxyBatchEngine {
        var steps: [any ScheduledProxyBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledProxyBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledProxyBatch) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledProxyBatchModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledProxyBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledProxyBatchEngine(_ flags: Kit.Flags.Registry) -> ScheduledProxyBatchEngine {
        return ScheduledProxyBatchEngine(
            steps: [
                CountryScheduledProxyBatchAdjuster(factors: ["south": 0.75]),
                PercentScheduledProxyBatchAdjuster(percent: -16.1),
                RoundingScheduledProxyBatchAdjuster(step: 0.25),
                TieredScheduledProxyBatchAdjuster(
                    bounds: [41.0, 222.0, 391.0, 5325.0],
                    rates: [0.98, 1.18, 1.01, 0.86]
                ),
                FlaggedScheduledProxyBatchAdjuster(flags: flags, flag: "scheduled-proxy-batch-default", percent: 1.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 67702.4
        )
    }
}
