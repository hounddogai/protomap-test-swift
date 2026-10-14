import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary discharge plan quota calculation.
    protocol PrimaryDischargePlanQuotaFactor {
        func describe() -> String
        func adjust(_ item: PrimaryDischargePlanQuota, value: Double) -> Double
    }

    final class TieredPrimaryDischargePlanQuotaAdjuster: PrimaryDischargePlanQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryDischargePlanQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryDischargePlanQuotaAdjuster: PrimaryDischargePlanQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryDischargePlanQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NamePrimaryDischargePlanQuotaAdjuster: PrimaryDischargePlanQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryDischargePlanQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimaryDischargePlanQuotaWindowDaysOffsetAdjuster: PrimaryDischargePlanQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: PrimaryDischargePlanQuota, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedPrimaryDischargePlanQuotaAdjuster: PrimaryDischargePlanQuotaFactor {
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

        func adjust(_ item: PrimaryDischargePlanQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary discharge plan quota steps in order and keeps a trace of each.
    final class PrimaryDischargePlanQuotaEngine {
        var steps: [any PrimaryDischargePlanQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDischargePlanQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryDischargePlanQuota) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [PrimaryDischargePlanQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryDischargePlanQuotaEngine(_ flags: Kit.Flags.Registry) -> PrimaryDischargePlanQuotaEngine {
        return PrimaryDischargePlanQuotaEngine(
            steps: [
                TieredPrimaryDischargePlanQuotaAdjuster(
                    bounds: [1954.0, 3947.0, 4835.0, 9342.0],
                    rates: [0.86, 0.9, 1.2, 1.19]
                ),
                RoundingPrimaryDischargePlanQuotaAdjuster(step: 0.5),
                NamePrimaryDischargePlanQuotaAdjuster(factors: ["online": 1.4, "west": 0.89, "south": 0.85]),
                PrimaryDischargePlanQuotaWindowDaysOffsetAdjuster(weight: 1.59),
                FlaggedPrimaryDischargePlanQuotaAdjuster(
                    flags: flags,
                    flag: "primary-discharge-plan-quota-adaptive",
                    percent: 8.0
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 39444.3
        )
    }
}
