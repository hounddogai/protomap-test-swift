import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback overtime policy calculation.
    protocol FallbackOvertimePolicyAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackOvertimePolicy, value: Double) -> Double
    }

    final class FlaggedFallbackOvertimePolicyAdjuster: FallbackOvertimePolicyAdjuster {
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

        func adjust(_ item: FallbackOvertimePolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackOvertimePolicyAdjuster: FallbackOvertimePolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackOvertimePolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackOvertimePolicyAdjuster: FallbackOvertimePolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackOvertimePolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackOvertimePolicyAdjuster: FallbackOvertimePolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackOvertimePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CategoryFallbackOvertimePolicyAdjuster: FallbackOvertimePolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FallbackOvertimePolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback overtime policy steps in order and keeps a trace of each.
    final class FallbackOvertimePolicyEngine {
        var steps: [any FallbackOvertimePolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackOvertimePolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackOvertimePolicy) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackOvertimePolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackOvertimePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackOvertimePolicyEngine(_ flags: Kit.Flags.Registry) -> FallbackOvertimePolicyEngine {
        return FallbackOvertimePolicyEngine(
            steps: [
                FlaggedFallbackOvertimePolicyAdjuster(
                    flags: flags,
                    flag: "fallback-overtime-policy-weighted",
                    percent: -6.1
                ),
                PercentFallbackOvertimePolicyAdjuster(percent: -0.5),
                CapFallbackOvertimePolicyAdjuster(cap: 45462.0),
                TieredFallbackOvertimePolicyAdjuster(
                    bounds: [994.0, 1927.0, 2154.0, 3040.0],
                    rates: [0.97, 0.98, 1.13, 0.87]
                ),
                CategoryFallbackOvertimePolicyAdjuster(factors: ["north": 0.92, "central": 1.16]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 4367.3
        )
    }
}
