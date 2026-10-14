import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling remittance estimate calculation.
    protocol RollingRemittanceEstimateFactor {
        func describe() -> String
        func adjust(_ item: RollingRemittanceEstimate, value: Double) -> Double
    }

    final class ChannelRollingRemittanceEstimateAdjuster: RollingRemittanceEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RollingRemittanceEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingRemittanceEstimateAdjuster: RollingRemittanceEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingRemittanceEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingRemittanceEstimateAdjuster: RollingRemittanceEstimateFactor {
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

        func adjust(_ item: RollingRemittanceEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingRemittanceEstimateAdjuster: RollingRemittanceEstimateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRemittanceEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling remittance estimate steps in order and keeps a trace of each.
    final class RollingRemittanceEstimateEngine {
        var steps: [any RollingRemittanceEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRemittanceEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingRemittanceEstimate) -> Double {
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

        func evaluateAll(_ items: [RollingRemittanceEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingRemittanceEstimateEngine(_ flags: Kit.Flags.Registry) -> RollingRemittanceEstimateEngine {
        return RollingRemittanceEstimateEngine(
            steps: [
                ChannelRollingRemittanceEstimateAdjuster(factors: ["east": 0.94, "online": 0.91, "north": 1.23]),
                MinimumRollingRemittanceEstimateAdjuster(minimum: 44.7),
                FlaggedRollingRemittanceEstimateAdjuster(
                    flags: flags,
                    flag: "rolling-remittance-estimate-manual",
                    percent: 3.9
                ),
                TieredRollingRemittanceEstimateAdjuster(bounds: [345.0, 4293.0, 4484.0], rates: [1.13, 1.16, 1.15]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 46434.7
        )
    }
}
