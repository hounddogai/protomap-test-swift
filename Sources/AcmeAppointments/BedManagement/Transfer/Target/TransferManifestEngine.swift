import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer manifest calculation.
    protocol TransferManifestStep {
        func describe() -> String
        func adjust(_ item: TransferManifest, value: Double) -> Double
    }

    final class FlaggedTransferManifestAdjuster: TransferManifestStep {
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

        func adjust(_ item: TransferManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTransferManifestAdjuster: TransferManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelTransferManifestAdjuster: TransferManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TransferManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTransferManifestAdjuster: TransferManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the transfer manifest steps in order and keeps a trace of each.
    final class TransferManifestEngine {
        var steps: [any TransferManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferManifest) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferManifestStep = steps[index]
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

        func evaluateAll(_ items: [TransferManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferManifestEngine(_ flags: Kit.Flags.Registry) -> TransferManifestEngine {
        return TransferManifestEngine(
            steps: [
                FlaggedTransferManifestAdjuster(flags: flags, flag: "transfer-manifest-batched", percent: -6.0),
                MinimumTransferManifestAdjuster(minimum: 36.9),
                ChannelTransferManifestAdjuster(factors: ["west": 0.87]),
                TieredTransferManifestAdjuster(bounds: [1581.0, 7260.0, 9144.0], rates: [1.09, 0.95, 0.83]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 25941.1
        )
    }
}
