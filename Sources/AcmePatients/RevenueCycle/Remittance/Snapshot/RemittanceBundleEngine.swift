import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance bundle calculation.
    protocol RemittanceBundleFactor {
        func describe() -> String
        func adjust(_ item: RemittanceBundle, value: Double) -> Double
    }

    final class FlaggedRemittanceBundleAdjuster: RemittanceBundleFactor {
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

        func adjust(_ item: RemittanceBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRemittanceBundleAdjuster: RemittanceBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRemittanceBundleAdjuster: RemittanceBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryRemittanceBundleAdjuster: RemittanceBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RemittanceBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRemittanceBundleAdjuster: RemittanceBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRemittanceBundleAdjuster: RemittanceBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the remittance bundle steps in order and keeps a trace of each.
    final class RemittanceBundleEngine {
        var steps: [any RemittanceBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceBundle) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceBundleFactor = steps[index]
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

        func evaluateAll(_ items: [RemittanceBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceBundleEngine(_ flags: Kit.Flags.Registry) -> RemittanceBundleEngine {
        return RemittanceBundleEngine(
            steps: [
                FlaggedRemittanceBundleAdjuster(flags: flags, flag: "remittance-bundle-rolling", percent: -8.6),
                RoundingRemittanceBundleAdjuster(step: 0.5),
                TieredRemittanceBundleAdjuster(bounds: [912.0, 8973.0], rates: [1.1, 1.02]),
                CountryRemittanceBundleAdjuster(factors: ["central": 1.28, "north": 1.37, "south": 1.09]),
                MinimumRemittanceBundleAdjuster(minimum: 2.1),
                PercentRemittanceBundleAdjuster(percent: 10.3),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 37674.5
        )
    }
}
