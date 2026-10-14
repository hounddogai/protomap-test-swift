import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling network quota calculation.
    protocol RollingNetworkQuotaStep {
        func describe() -> String
        func adjust(_ item: RollingNetworkQuota, value: Double) -> Double
    }

    final class PercentRollingNetworkQuotaAdjuster: RollingNetworkQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingNetworkQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingNetworkQuotaAdjuster: RollingNetworkQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingNetworkQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingNetworkQuotaAdjuster: RollingNetworkQuotaStep {
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

        func adjust(_ item: RollingNetworkQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingNetworkQuotaAcuityOffsetAdjuster: RollingNetworkQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RollingNetworkQuota, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredRollingNetworkQuotaAdjuster: RollingNetworkQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingNetworkQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling network quota steps in order and keeps a trace of each.
    final class RollingNetworkQuotaEngine {
        var steps: [any RollingNetworkQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingNetworkQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingNetworkQuota) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [RollingNetworkQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingNetworkQuotaEngine(_ flags: Kit.Flags.Registry) -> RollingNetworkQuotaEngine {
        return RollingNetworkQuotaEngine(
            steps: [
                PercentRollingNetworkQuotaAdjuster(percent: 3.2),
                MinimumRollingNetworkQuotaAdjuster(minimum: 21.9),
                FlaggedRollingNetworkQuotaAdjuster(flags: flags, flag: "rolling-network-quota-regional", percent: 2.2),
                RollingNetworkQuotaAcuityOffsetAdjuster(weight: 1.04),
                TieredRollingNetworkQuotaAdjuster(bounds: [2610.0, 8163.0], rates: [0.81, 1.08]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 59413.5
        )
    }
}
