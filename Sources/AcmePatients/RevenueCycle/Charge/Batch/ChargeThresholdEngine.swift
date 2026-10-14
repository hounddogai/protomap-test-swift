import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge threshold calculation.
    protocol ChargeThresholdModifier {
        func describe() -> String
        func adjust(_ item: ChargeThreshold, value: Double) -> Double
    }

    final class PercentChargeThresholdAdjuster: ChargeThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedChargeThresholdAdjuster: ChargeThresholdModifier {
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

        func adjust(_ item: ChargeThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredChargeThresholdAdjuster: ChargeThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameChargeThresholdAdjuster: ChargeThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ChargeThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the charge threshold steps in order and keeps a trace of each.
    final class ChargeThresholdEngine {
        var steps: [any ChargeThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ChargeThreshold) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [ChargeThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultChargeThresholdEngine(_ flags: Kit.Flags.Registry) -> ChargeThresholdEngine {
        return ChargeThresholdEngine(
            steps: [
                PercentChargeThresholdAdjuster(percent: 23.9),
                FlaggedChargeThresholdAdjuster(flags: flags, flag: "charge-threshold-legacy", percent: -5.5),
                TieredChargeThresholdAdjuster(
                    bounds: [838.0, 1875.0, 2067.0, 5120.0],
                    rates: [1.14, 1.09, 1.02, 0.99]
                ),
                NameChargeThresholdAdjuster(factors: ["retail": 1.28, "north": 0.86, "west": 1.0]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 22249.0
        )
    }
}
