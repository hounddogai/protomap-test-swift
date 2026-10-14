import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge variance calculation.
    protocol ChargeVarianceStep {
        func describe() -> String
        func adjust(_ item: ChargeVariance, value: Double) -> Double
    }

    final class RoundingChargeVarianceAdjuster: ChargeVarianceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleChargeVarianceAdjuster: ChargeVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ChargeVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentChargeVarianceAdjuster: ChargeVarianceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredChargeVarianceAdjuster: ChargeVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedChargeVarianceAdjuster: ChargeVarianceStep {
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

        func adjust(_ item: ChargeVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge variance steps in order and keeps a trace of each.
    final class ChargeVarianceEngine {
        var steps: [any ChargeVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeVariance) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeVarianceStep = steps[index]
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

        func evaluateAll(_ items: [ChargeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeVarianceEngine(_ flags: Kit.Flags.Registry) -> ChargeVarianceEngine {
        return ChargeVarianceEngine(
            steps: [
                RoundingChargeVarianceAdjuster(step: 0.5),
                TitleChargeVarianceAdjuster(factors: ["south": 1.23, "east": 0.83]),
                PercentChargeVarianceAdjuster(percent: -11.6),
                TieredChargeVarianceAdjuster(bounds: [1228.0, 3875.0], rates: [1.15, 0.97]),
                FlaggedChargeVarianceAdjuster(flags: flags, flag: "charge-variance-primary", percent: -7.5),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 29999.3
        )
    }
}
