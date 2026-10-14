import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary acuity plan quota calculation.
    protocol PrimaryAcuityPlanQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryAcuityPlanQuota, value: Double) -> Double
    }

    final class TieredPrimaryAcuityPlanQuotaAdjuster: PrimaryAcuityPlanQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryAcuityPlanQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPrimaryAcuityPlanQuotaAdjuster: PrimaryAcuityPlanQuotaAdjuster {
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

        func adjust(_ item: PrimaryAcuityPlanQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryAcuityPlanQuotaAdjuster: PrimaryAcuityPlanQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryAcuityPlanQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary acuity plan quota steps in order and keeps a trace of each.
    final class PrimaryAcuityPlanQuotaEngine {
        var steps: [any PrimaryAcuityPlanQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAcuityPlanQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryAcuityPlanQuota) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [PrimaryAcuityPlanQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryAcuityPlanQuotaEngine(_ flags: Kit.Flags.Registry) -> PrimaryAcuityPlanQuotaEngine {
        return PrimaryAcuityPlanQuotaEngine(
            steps: [
                TieredPrimaryAcuityPlanQuotaAdjuster(
                    bounds: [3422.0, 3797.0, 9183.0, 9888.0],
                    rates: [1.2, 0.93, 0.92, 1.06]
                ),
                FlaggedPrimaryAcuityPlanQuotaAdjuster(
                    flags: flags,
                    flag: "primary-acuity-plan-quota-global",
                    percent: 2.1
                ),
                PercentPrimaryAcuityPlanQuotaAdjuster(percent: -11.4),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 38643.0
        )
    }
}
