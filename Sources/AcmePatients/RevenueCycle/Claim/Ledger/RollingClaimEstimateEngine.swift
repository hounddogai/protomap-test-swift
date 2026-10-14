import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling claim estimate calculation.
    protocol RollingClaimEstimateModifier {
        func describe() -> String
        func adjust(_ item: RollingClaimEstimate, value: Double) -> Double
    }

    final class MinimumRollingClaimEstimateAdjuster: RollingClaimEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingClaimEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingClaimEstimateAdjuster: RollingClaimEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingClaimEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleRollingClaimEstimateAdjuster: RollingClaimEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingClaimEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingClaimEstimateAdjuster: RollingClaimEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingClaimEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingClaimEstimateAdjuster: RollingClaimEstimateModifier {
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

        func adjust(_ item: RollingClaimEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling claim estimate steps in order and keeps a trace of each.
    final class RollingClaimEstimateEngine {
        var steps: [any RollingClaimEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClaimEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingClaimEstimate) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingClaimEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [RollingClaimEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingClaimEstimateEngine(_ flags: Kit.Flags.Registry) -> RollingClaimEstimateEngine {
        return RollingClaimEstimateEngine(
            steps: [
                MinimumRollingClaimEstimateAdjuster(minimum: 47.7),
                TieredRollingClaimEstimateAdjuster(bounds: [4130.0, 7360.0], rates: [0.92, 0.83]),
                TitleRollingClaimEstimateAdjuster(factors: ["south": 1.05, "west": 0.76, "retail": 1.38]),
                PercentRollingClaimEstimateAdjuster(percent: 12.3),
                FlaggedRollingClaimEstimateAdjuster(
                    flags: flags,
                    flag: "rolling-claim-estimate-default",
                    percent: -3.3
                ),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 55516.0
        )
    }
}
