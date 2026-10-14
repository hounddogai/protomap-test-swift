import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted transfer variance calculation.
    protocol WeightedTransferVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedTransferVariance, value: Double) -> Double
    }

    final class TieredWeightedTransferVarianceAdjuster: WeightedTransferVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedTransferVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionWeightedTransferVarianceAdjuster: WeightedTransferVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedTransferVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWeightedTransferVarianceAdjuster: WeightedTransferVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedTransferVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedTransferVarianceAdjuster: WeightedTransferVarianceAdjuster {
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

        func adjust(_ item: WeightedTransferVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted transfer variance steps in order and keeps a trace of each.
    final class WeightedTransferVarianceEngine {
        var steps: [any WeightedTransferVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTransferVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedTransferVariance) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedTransferVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedTransferVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedTransferVarianceEngine(_ flags: Kit.Flags.Registry) -> WeightedTransferVarianceEngine {
        return WeightedTransferVarianceEngine(
            steps: [
                TieredWeightedTransferVarianceAdjuster(bounds: [399.0, 2151.0, 3054.0], rates: [0.8, 0.99, 0.9]),
                RegionWeightedTransferVarianceAdjuster(factors: ["retail": 1.32, "west": 0.93, "south": 0.7]),
                RoundingWeightedTransferVarianceAdjuster(step: 1.0),
                FlaggedWeightedTransferVarianceAdjuster(
                    flags: flags,
                    flag: "weighted-transfer-variance-manual",
                    percent: 1.9
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 62641.3
        )
    }
}
