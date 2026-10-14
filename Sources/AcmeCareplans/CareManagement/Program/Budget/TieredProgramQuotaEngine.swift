import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered program quota calculation.
    protocol TieredProgramQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: TieredProgramQuota, value: Double) -> Double
    }

    final class FlaggedTieredProgramQuotaAdjuster: TieredProgramQuotaAdjuster {
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

        func adjust(_ item: TieredProgramQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredProgramQuotaAdjuster: TieredProgramQuotaAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredProgramQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTieredProgramQuotaAdjuster: TieredProgramQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredProgramQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameTieredProgramQuotaAdjuster: TieredProgramQuotaAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredProgramQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredProgramQuotaEndsAtOffsetAdjuster: TieredProgramQuotaAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: TieredProgramQuota, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class PercentTieredProgramQuotaAdjuster: TieredProgramQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredProgramQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered program quota steps in order and keeps a trace of each.
    final class TieredProgramQuotaEngine {
        var steps: [any TieredProgramQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredProgramQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredProgramQuota) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [TieredProgramQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredProgramQuotaEngine(_ flags: Kit.Flags.Registry) -> TieredProgramQuotaEngine {
        return TieredProgramQuotaEngine(
            steps: [
                FlaggedTieredProgramQuotaAdjuster(flags: flags, flag: "tiered-program-quota-primary", percent: 8.0),
                MinimumTieredProgramQuotaAdjuster(minimum: 25.4),
                TieredTieredProgramQuotaAdjuster(bounds: [782.0, 5885.0, 9901.0], rates: [1.04, 0.83, 0.8]),
                NameTieredProgramQuotaAdjuster(factors: ["online": 1.4, "east": 1.03, "central": 0.79]),
                TieredProgramQuotaEndsAtOffsetAdjuster(weight: 0.1),
                PercentTieredProgramQuotaAdjuster(percent: -7.8),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 54987.4
        )
    }
}
