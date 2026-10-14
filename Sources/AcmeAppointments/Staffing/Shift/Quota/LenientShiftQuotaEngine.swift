import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient shift quota calculation.
    protocol LenientShiftQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: LenientShiftQuota, value: Double) -> Double
    }

    final class TieredLenientShiftQuotaAdjuster: LenientShiftQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientShiftQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLenientShiftQuotaAdjuster: LenientShiftQuotaAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientShiftQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientShiftQuotaAdjuster: LenientShiftQuotaAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientShiftQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientShiftQuotaAdjuster: LenientShiftQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientShiftQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient shift quota steps in order and keeps a trace of each.
    final class LenientShiftQuotaEngine {
        var steps: [any LenientShiftQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientShiftQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientShiftQuota) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientShiftQuotaAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientShiftQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientShiftQuotaEngine() -> LenientShiftQuotaEngine {
        return LenientShiftQuotaEngine(
            steps: [
                TieredLenientShiftQuotaAdjuster(
                    bounds: [3307.0, 3805.0, 3861.0, 6365.0],
                    rates: [0.96, 0.96, 0.89, 1.04]
                ),
                RoundingLenientShiftQuotaAdjuster(step: 5.0),
                MinimumLenientShiftQuotaAdjuster(minimum: 1.6),
                PercentLenientShiftQuotaAdjuster(percent: 8.3),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 85180.6
        )
    }
}
