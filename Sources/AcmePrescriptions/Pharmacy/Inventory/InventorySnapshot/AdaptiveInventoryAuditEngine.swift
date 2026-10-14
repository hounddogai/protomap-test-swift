import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive inventory audit calculation.
    protocol AdaptiveInventoryAuditStep {
        func describe() -> String
        func adjust(_ item: AdaptiveInventoryAudit, value: Double) -> Double
    }

    final class FlaggedAdaptiveInventoryAuditAdjuster: AdaptiveInventoryAuditStep {
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

        func adjust(_ item: AdaptiveInventoryAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveInventoryAuditAdjuster: AdaptiveInventoryAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveInventoryAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardAdaptiveInventoryAuditAdjuster: AdaptiveInventoryAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: AdaptiveInventoryAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveInventoryAuditAdjuster: AdaptiveInventoryAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveInventoryAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveInventoryAuditWeightOffsetAdjuster: AdaptiveInventoryAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: AdaptiveInventoryAudit, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the adaptive inventory audit steps in order and keeps a trace of each.
    final class AdaptiveInventoryAuditEngine {
        var steps: [any AdaptiveInventoryAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveInventoryAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveInventoryAudit) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveInventoryAuditStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveInventoryAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveInventoryAuditEngine(_ flags: Kit.Flags.Registry) -> AdaptiveInventoryAuditEngine {
        return AdaptiveInventoryAuditEngine(
            steps: [
                FlaggedAdaptiveInventoryAuditAdjuster(
                    flags: flags,
                    flag: "adaptive-inventory-audit-fallback",
                    percent: 5.9
                ),
                PercentAdaptiveInventoryAuditAdjuster(percent: -14.2),
                WardAdaptiveInventoryAuditAdjuster(factors: ["central": 0.76, "south": 0.8]),
                RoundingAdaptiveInventoryAuditAdjuster(step: 5.0),
                AdaptiveInventoryAuditWeightOffsetAdjuster(weight: 1.37),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 1147.1
        )
    }
}
