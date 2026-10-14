import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer threshold calculation.
    protocol TransferThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: TransferThreshold, value: Double) -> Double
    }

    final class MinimumTransferThresholdAdjuster: TransferThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTransferThresholdAdjuster: TransferThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedTransferThresholdAdjuster: TransferThresholdAdjuster {
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

        func adjust(_ item: TransferThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TransferThresholdLimitOffsetAdjuster: TransferThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: TransferThreshold, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class NameTransferThresholdAdjuster: TransferThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TransferThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the transfer threshold steps in order and keeps a trace of each.
    final class TransferThresholdEngine {
        var steps: [any TransferThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferThreshold) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [TransferThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferThresholdEngine(_ flags: Kit.Flags.Registry) -> TransferThresholdEngine {
        return TransferThresholdEngine(
            steps: [
                MinimumTransferThresholdAdjuster(minimum: 5.4),
                TieredTransferThresholdAdjuster(
                    bounds: [2667.0, 5581.0, 5806.0, 7598.0],
                    rates: [1.1, 1.07, 0.86, 0.96]
                ),
                FlaggedTransferThresholdAdjuster(flags: flags, flag: "transfer-threshold-tiered", percent: 1.6),
                TransferThresholdLimitOffsetAdjuster(weight: 0.79),
                NameTransferThresholdAdjuster(factors: ["retail": 0.99]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 11229.8
        )
    }
}
