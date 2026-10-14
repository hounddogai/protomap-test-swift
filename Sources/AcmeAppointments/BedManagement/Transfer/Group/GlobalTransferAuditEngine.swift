import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global transfer audit calculation.
    protocol GlobalTransferAuditFactor {
        func describe() -> String
        func adjust(_ item: GlobalTransferAudit, value: Double) -> Double
    }

    final class TieredGlobalTransferAuditAdjuster: GlobalTransferAuditFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalTransferAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalTransferAuditAdjuster: GlobalTransferAuditFactor {
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

        func adjust(_ item: GlobalTransferAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalTransferAuditAdjuster: GlobalTransferAuditFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalTransferAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalTransferAuditThresholdOffsetAdjuster: GlobalTransferAuditFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: GlobalTransferAudit, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the global transfer audit steps in order and keeps a trace of each.
    final class GlobalTransferAuditEngine {
        var steps: [any GlobalTransferAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalTransferAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalTransferAudit) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalTransferAuditFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalTransferAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalTransferAuditEngine(_ flags: Kit.Flags.Registry) -> GlobalTransferAuditEngine {
        return GlobalTransferAuditEngine(
            steps: [
                TieredGlobalTransferAuditAdjuster(
                    bounds: [315.0, 2445.0, 7050.0, 7729.0],
                    rates: [0.85, 1.07, 1.11, 1.09]
                ),
                FlaggedGlobalTransferAuditAdjuster(flags: flags, flag: "global-transfer-audit-manual", percent: -1.5),
                CapGlobalTransferAuditAdjuster(cap: 45076.0),
                GlobalTransferAuditThresholdOffsetAdjuster(weight: 0.89),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 49205.6
        )
    }
}
