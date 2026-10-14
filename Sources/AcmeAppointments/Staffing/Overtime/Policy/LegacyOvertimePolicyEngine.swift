import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy overtime policy calculation.
    protocol LegacyOvertimePolicyAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double
    }

    final class MinimumLegacyOvertimePolicyAdjuster: LegacyOvertimePolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyOvertimePolicyAdjuster: LegacyOvertimePolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyOvertimePolicyAdjuster: LegacyOvertimePolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLegacyOvertimePolicyAdjuster: LegacyOvertimePolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelLegacyOvertimePolicyAdjuster: LegacyOvertimePolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyOvertimePolicyAdjuster: LegacyOvertimePolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyOvertimePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy overtime policy steps in order and keeps a trace of each.
    final class LegacyOvertimePolicyEngine {
        var steps: [any LegacyOvertimePolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyOvertimePolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyOvertimePolicy) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyOvertimePolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyOvertimePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyOvertimePolicyEngine() -> LegacyOvertimePolicyEngine {
        return LegacyOvertimePolicyEngine(
            steps: [
                MinimumLegacyOvertimePolicyAdjuster(minimum: 22.7),
                PercentLegacyOvertimePolicyAdjuster(percent: 9.3),
                CapLegacyOvertimePolicyAdjuster(cap: 33707.0),
                RoundingLegacyOvertimePolicyAdjuster(step: 0.05),
                ChannelLegacyOvertimePolicyAdjuster(factors: ["retail": 1.22]),
                TieredLegacyOvertimePolicyAdjuster(bounds: [5564.0, 6523.0, 8712.0], rates: [1.11, 1.07, 1.05]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 50320.4
        )
    }
}
