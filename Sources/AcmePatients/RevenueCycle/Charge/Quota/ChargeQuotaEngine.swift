import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge quota calculation.
    protocol ChargeQuotaStep {
        func describe() -> String
        func adjust(_ item: ChargeQuota, value: Double) -> Double
    }

    final class CapChargeQuotaAdjuster: ChargeQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredChargeQuotaAdjuster: ChargeQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingChargeQuotaAdjuster: ChargeQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedChargeQuotaAdjuster: ChargeQuotaStep {
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

        func adjust(_ item: ChargeQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChargeQuotaDosageMgOffsetAdjuster: ChargeQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ChargeQuota, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentChargeQuotaAdjuster: ChargeQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge quota steps in order and keeps a trace of each.
    final class ChargeQuotaEngine {
        var steps: [any ChargeQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ChargeQuota) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ChargeQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultChargeQuotaEngine(_ flags: Kit.Flags.Registry) -> ChargeQuotaEngine {
        return ChargeQuotaEngine(
            steps: [
                CapChargeQuotaAdjuster(cap: 45898.0),
                TieredChargeQuotaAdjuster(bounds: [1662.0, 2197.0, 2389.0, 8726.0], rates: [0.96, 1.05, 0.97, 1.09]),
                RoundingChargeQuotaAdjuster(step: 1.0),
                FlaggedChargeQuotaAdjuster(flags: flags, flag: "charge-quota-seasonal", percent: 5.3),
                ChargeQuotaDosageMgOffsetAdjuster(weight: 1.67),
                PercentChargeQuotaAdjuster(percent: -12.6),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 19198.8
        )
    }
}
