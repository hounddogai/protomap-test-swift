import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary float pool quota calculation.
    protocol PrimaryFloatPoolQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryFloatPoolQuota, value: Double) -> Double
    }

    final class PercentPrimaryFloatPoolQuotaAdjuster: PrimaryFloatPoolQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryFloatPoolQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryFloatPoolQuotaAdjuster: PrimaryFloatPoolQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryFloatPoolQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPrimaryFloatPoolQuotaAdjuster: PrimaryFloatPoolQuotaAdjuster {
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

        func adjust(_ item: PrimaryFloatPoolQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryFloatPoolQuotaAdjuster: PrimaryFloatPoolQuotaAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryFloatPoolQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary float pool quota steps in order and keeps a trace of each.
    final class PrimaryFloatPoolQuotaEngine {
        var steps: [any PrimaryFloatPoolQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryFloatPoolQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryFloatPoolQuota) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [PrimaryFloatPoolQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryFloatPoolQuotaEngine(_ flags: Kit.Flags.Registry) -> PrimaryFloatPoolQuotaEngine {
        return PrimaryFloatPoolQuotaEngine(
            steps: [
                PercentPrimaryFloatPoolQuotaAdjuster(percent: -13.3),
                TieredPrimaryFloatPoolQuotaAdjuster(bounds: [7466.0, 7803.0, 8059.0], rates: [0.98, 0.81, 0.93]),
                FlaggedPrimaryFloatPoolQuotaAdjuster(
                    flags: flags,
                    flag: "primary-float-pool-quota-seasonal",
                    percent: -2.7
                ),
                RoundingPrimaryFloatPoolQuotaAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 92122.4
        )
    }
}
