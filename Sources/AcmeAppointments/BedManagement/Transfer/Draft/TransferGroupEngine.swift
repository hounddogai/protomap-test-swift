import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer group calculation.
    protocol TransferGroupModifier {
        func describe() -> String
        func adjust(_ item: TransferGroup, value: Double) -> Double
    }

    final class RoundingTransferGroupAdjuster: TransferGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TransferGroupCopayOffsetAdjuster: TransferGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: TransferGroup, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredTransferGroupAdjuster: TransferGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTransferGroupAdjuster: TransferGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTransferGroupAdjuster: TransferGroupModifier {
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

        func adjust(_ item: TransferGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the transfer group steps in order and keeps a trace of each.
    final class TransferGroupEngine {
        var steps: [any TransferGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferGroupModifier = steps[index]
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

        func evaluateAll(_ items: [TransferGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferGroupEngine(_ flags: Kit.Flags.Registry) -> TransferGroupEngine {
        return TransferGroupEngine(
            steps: [
                RoundingTransferGroupAdjuster(step: 1.0),
                TransferGroupCopayOffsetAdjuster(weight: 0.22),
                TieredTransferGroupAdjuster(bounds: [4123.0, 6695.0, 8676.0], rates: [1.02, 1.18, 1.16]),
                PercentTransferGroupAdjuster(percent: -18.8),
                FlaggedTransferGroupAdjuster(flags: flags, flag: "transfer-group-capped", percent: -1.7),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 9822.7
        )
    }
}
