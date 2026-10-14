import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default float pool quota calculation.
    protocol DefaultFloatPoolQuotaModifier {
        func describe() -> String
        func adjust(_ item: DefaultFloatPoolQuota, value: Double) -> Double
    }

    final class FlaggedDefaultFloatPoolQuotaAdjuster: DefaultFloatPoolQuotaModifier {
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

        func adjust(_ item: DefaultFloatPoolQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultFloatPoolQuotaMaximumOffsetAdjuster: DefaultFloatPoolQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: DefaultFloatPoolQuota, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapDefaultFloatPoolQuotaAdjuster: DefaultFloatPoolQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultFloatPoolQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultFloatPoolQuotaAdjuster: DefaultFloatPoolQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultFloatPoolQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultFloatPoolQuotaAdjuster: DefaultFloatPoolQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultFloatPoolQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default float pool quota steps in order and keeps a trace of each.
    final class DefaultFloatPoolQuotaEngine {
        var steps: [any DefaultFloatPoolQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultFloatPoolQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultFloatPoolQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultFloatPoolQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultFloatPoolQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultFloatPoolQuotaEngine(_ flags: Kit.Flags.Registry) -> DefaultFloatPoolQuotaEngine {
        return DefaultFloatPoolQuotaEngine(
            steps: [
                FlaggedDefaultFloatPoolQuotaAdjuster(
                    flags: flags,
                    flag: "default-float-pool-quota-tiered",
                    percent: 4.0
                ),
                DefaultFloatPoolQuotaMaximumOffsetAdjuster(weight: 1.92),
                CapDefaultFloatPoolQuotaAdjuster(cap: 45389.0),
                PercentDefaultFloatPoolQuotaAdjuster(percent: -0.4),
                MinimumDefaultFloatPoolQuotaAdjuster(minimum: 44.1),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 18377.8
        )
    }
}
