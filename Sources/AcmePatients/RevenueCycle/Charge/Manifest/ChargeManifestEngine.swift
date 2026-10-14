import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge manifest calculation.
    protocol ChargeManifestStep {
        func describe() -> String
        func adjust(_ item: ChargeManifest, value: Double) -> Double
    }

    final class TieredChargeManifestAdjuster: ChargeManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentChargeManifestAdjuster: ChargeManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleChargeManifestAdjuster: ChargeManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ChargeManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingChargeManifestAdjuster: ChargeManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumChargeManifestAdjuster: ChargeManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedChargeManifestAdjuster: ChargeManifestStep {
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

        func adjust(_ item: ChargeManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge manifest steps in order and keeps a trace of each.
    final class ChargeManifestEngine {
        var steps: [any ChargeManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeManifest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeManifestStep = steps[index]
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

        func evaluateAll(_ items: [ChargeManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeManifestEngine(_ flags: Kit.Flags.Registry) -> ChargeManifestEngine {
        return ChargeManifestEngine(
            steps: [
                TieredChargeManifestAdjuster(bounds: [462.0, 8025.0], rates: [1.19, 0.98]),
                PercentChargeManifestAdjuster(percent: -8.8),
                TitleChargeManifestAdjuster(factors: ["retail": 1.01, "south": 0.84]),
                RoundingChargeManifestAdjuster(step: 5.0),
                MinimumChargeManifestAdjuster(minimum: 1.6),
                FlaggedChargeManifestAdjuster(flags: flags, flag: "charge-manifest-rolling", percent: -7.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 63828.6
        )
    }
}
