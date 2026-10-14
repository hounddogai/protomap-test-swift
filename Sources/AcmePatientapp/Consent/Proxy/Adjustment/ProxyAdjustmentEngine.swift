import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy adjustment calculation.
    protocol ProxyAdjustmentStep {
        func describe() -> String
        func adjust(_ item: ProxyAdjustment, value: Double) -> Double
    }

    final class LabelProxyAdjustmentAdjuster: ProxyAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ProxyAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentProxyAdjustmentAdjuster: ProxyAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumProxyAdjustmentAdjuster: ProxyAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapProxyAdjustmentAdjuster: ProxyAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedProxyAdjustmentAdjuster: ProxyAdjustmentStep {
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

        func adjust(_ item: ProxyAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ProxyAdjustmentEndsAtOffsetAdjuster: ProxyAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ProxyAdjustment, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the proxy adjustment steps in order and keeps a trace of each.
    final class ProxyAdjustmentEngine {
        var steps: [any ProxyAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyAdjustment) -> Double {
            var current = item.weightedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ProxyAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyAdjustmentEngine(_ flags: Kit.Flags.Registry) -> ProxyAdjustmentEngine {
        return ProxyAdjustmentEngine(
            steps: [
                LabelProxyAdjustmentAdjuster(factors: ["east": 0.98, "south": 1.21, "west": 0.95]),
                PercentProxyAdjustmentAdjuster(percent: -12.2),
                MinimumProxyAdjustmentAdjuster(minimum: 25.3),
                CapProxyAdjustmentAdjuster(cap: 3231.0),
                FlaggedProxyAdjustmentAdjuster(flags: flags, flag: "proxy-adjustment-manual", percent: 2.4),
                ProxyAdjustmentEndsAtOffsetAdjuster(weight: 1.23),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 74362.3
        )
    }
}
