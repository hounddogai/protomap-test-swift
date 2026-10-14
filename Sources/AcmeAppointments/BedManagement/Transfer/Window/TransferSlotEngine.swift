import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer slot calculation.
    protocol TransferSlotStep {
        func describe() -> String
        func adjust(_ item: TransferSlot, value: Double) -> Double
    }

    final class CapTransferSlotAdjuster: TransferSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTransferSlotAdjuster: TransferSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTransferSlotAdjuster: TransferSlotStep {
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

        func adjust(_ item: TransferSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTransferSlotAdjuster: TransferSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the transfer slot steps in order and keeps a trace of each.
    final class TransferSlotEngine {
        var steps: [any TransferSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferSlot) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [TransferSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferSlotEngine(_ flags: Kit.Flags.Registry) -> TransferSlotEngine {
        return TransferSlotEngine(
            steps: [
                CapTransferSlotAdjuster(cap: 19517.0),
                MinimumTransferSlotAdjuster(minimum: 14.1),
                FlaggedTransferSlotAdjuster(flags: flags, flag: "transfer-slot-regional", percent: 4.2),
                PercentTransferSlotAdjuster(percent: 18.9),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 84829.1
        )
    }
}
