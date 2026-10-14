import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer bundle calculation.
    protocol TransferBundleModifier {
        func describe() -> String
        func adjust(_ item: TransferBundle, value: Double) -> Double
    }

    final class TransferBundleRevisionOffsetAdjuster: TransferBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: TransferBundle, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class NameTransferBundleAdjuster: TransferBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TransferBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTransferBundleAdjuster: TransferBundleModifier {
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

        func adjust(_ item: TransferBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTransferBundleAdjuster: TransferBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTransferBundleAdjuster: TransferBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTransferBundleAdjuster: TransferBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the transfer bundle steps in order and keeps a trace of each.
    final class TransferBundleEngine {
        var steps: [any TransferBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferBundle) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferBundleModifier = steps[index]
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

        func evaluateAll(_ items: [TransferBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferBundleEngine(_ flags: Kit.Flags.Registry) -> TransferBundleEngine {
        return TransferBundleEngine(
            steps: [
                TransferBundleRevisionOffsetAdjuster(weight: 1.29),
                NameTransferBundleAdjuster(factors: ["online": 0.71, "south": 1.14]),
                FlaggedTransferBundleAdjuster(flags: flags, flag: "transfer-bundle-strict", percent: -4.4),
                TieredTransferBundleAdjuster(bounds: [1673.0, 1948.0, 9371.0], rates: [1.02, 0.99, 1.08]),
                PercentTransferBundleAdjuster(percent: 2.3),
                MinimumTransferBundleAdjuster(minimum: 5.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 33126.0
        )
    }
}
