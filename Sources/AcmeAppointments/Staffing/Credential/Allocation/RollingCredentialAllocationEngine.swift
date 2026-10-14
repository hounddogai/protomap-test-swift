import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling credential allocation calculation.
    protocol RollingCredentialAllocationFactor {
        func describe() -> String
        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double
    }

    final class SourceRollingCredentialAllocationAdjuster: RollingCredentialAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingCredentialAllocationAdjuster: RollingCredentialAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingCredentialAllocationAdjuster: RollingCredentialAllocationFactor {
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

        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingCredentialAllocationAdjuster: RollingCredentialAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingCredentialAllocationAdjuster: RollingCredentialAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingCredentialAllocationAdjuster: RollingCredentialAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCredentialAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling credential allocation steps in order and keeps a trace of each.
    final class RollingCredentialAllocationEngine {
        var steps: [any RollingCredentialAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCredentialAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingCredentialAllocation) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCredentialAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [RollingCredentialAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingCredentialAllocationEngine(_ flags: Kit.Flags.Registry) -> RollingCredentialAllocationEngine {
        return RollingCredentialAllocationEngine(
            steps: [
                SourceRollingCredentialAllocationAdjuster(factors: ["west": 1.08, "central": 0.87]),
                PercentRollingCredentialAllocationAdjuster(percent: 20.5),
                FlaggedRollingCredentialAllocationAdjuster(
                    flags: flags,
                    flag: "rolling-credential-allocation-rolling",
                    percent: 6.9
                ),
                TieredRollingCredentialAllocationAdjuster(bounds: [6873.0, 8187.0, 9421.0], rates: [1.04, 1.08, 1.08]),
                CapRollingCredentialAllocationAdjuster(cap: 31887.0),
                RoundingRollingCredentialAllocationAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 45006.9
        )
    }
}
