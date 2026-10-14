import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default specimen quota calculation.
    protocol DefaultSpecimenQuotaFactor {
        func describe() -> String
        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double
    }

    final class TieredDefaultSpecimenQuotaAdjuster: DefaultSpecimenQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultSpecimenQuotaAdjuster: DefaultSpecimenQuotaFactor {
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

        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultSpecimenQuotaAdjuster: DefaultSpecimenQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultSpecimenQuotaAdjuster: DefaultSpecimenQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardDefaultSpecimenQuotaAdjuster: DefaultSpecimenQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultSpecimenQuotaAdjuster: DefaultSpecimenQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultSpecimenQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default specimen quota steps in order and keeps a trace of each.
    final class DefaultSpecimenQuotaEngine {
        var steps: [any DefaultSpecimenQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSpecimenQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultSpecimenQuota) -> Double {
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

        func evaluateAll(_ items: [DefaultSpecimenQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultSpecimenQuotaEngine(_ flags: Kit.Flags.Registry) -> DefaultSpecimenQuotaEngine {
        return DefaultSpecimenQuotaEngine(
            steps: [
                TieredDefaultSpecimenQuotaAdjuster(bounds: [268.0, 2926.0, 3060.0], rates: [0.87, 0.97, 0.86]),
                FlaggedDefaultSpecimenQuotaAdjuster(
                    flags: flags,
                    flag: "default-specimen-quota-capped",
                    percent: -9.5
                ),
                CapDefaultSpecimenQuotaAdjuster(cap: 21655.0),
                RoundingDefaultSpecimenQuotaAdjuster(step: 1.0),
                WardDefaultSpecimenQuotaAdjuster(factors: ["north": 1.37, "east": 1.01, "west": 0.72]),
                PercentDefaultSpecimenQuotaAdjuster(percent: -22.7),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 77354.0
        )
    }
}
