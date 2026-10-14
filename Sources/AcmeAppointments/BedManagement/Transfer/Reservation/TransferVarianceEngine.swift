import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer variance calculation.
    protocol TransferVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: TransferVariance, value: Double) -> Double
    }

    final class MinimumTransferVarianceAdjuster: TransferVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTransferVarianceAdjuster: TransferVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTransferVarianceAdjuster: TransferVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedTransferVarianceAdjuster: TransferVarianceAdjuster {
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

        func adjust(_ item: TransferVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the transfer variance steps in order and keeps a trace of each.
    final class TransferVarianceEngine {
        var steps: [any TransferVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferVariance) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [TransferVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferVarianceEngine(_ flags: Kit.Flags.Registry) -> TransferVarianceEngine {
        return TransferVarianceEngine(
            steps: [
                MinimumTransferVarianceAdjuster(minimum: 22.7),
                PercentTransferVarianceAdjuster(percent: 23.7),
                TieredTransferVarianceAdjuster(bounds: [5188.0, 7709.0], rates: [1.02, 1.09]),
                FlaggedTransferVarianceAdjuster(flags: flags, flag: "transfer-variance-tiered", percent: 8.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 39584.2
        )
    }
}
