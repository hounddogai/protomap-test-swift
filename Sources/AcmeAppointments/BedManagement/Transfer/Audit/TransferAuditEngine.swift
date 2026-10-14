import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer audit calculation.
    protocol TransferAuditAdjuster {
        func describe() -> String
        func adjust(_ item: TransferAudit, value: Double) -> Double
    }

    final class FlaggedTransferAuditAdjuster: TransferAuditAdjuster {
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

        func adjust(_ item: TransferAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceTransferAuditAdjuster: TransferAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TransferAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTransferAuditAdjuster: TransferAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTransferAuditAdjuster: TransferAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the transfer audit steps in order and keeps a trace of each.
    final class TransferAuditEngine {
        var steps: [any TransferAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferAudit) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [TransferAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferAuditEngine(_ flags: Kit.Flags.Registry) -> TransferAuditEngine {
        return TransferAuditEngine(
            steps: [
                FlaggedTransferAuditAdjuster(flags: flags, flag: "transfer-audit-fallback", percent: -8.7),
                SourceTransferAuditAdjuster(factors: ["online": 1.04, "north": 0.84, "west": 0.92]),
                PercentTransferAuditAdjuster(percent: 6.8),
                RoundingTransferAuditAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 36305.3
        )
    }
}
