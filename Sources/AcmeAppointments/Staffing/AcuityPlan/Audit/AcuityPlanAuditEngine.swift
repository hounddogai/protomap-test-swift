import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan audit calculation.
    protocol AcuityPlanAuditModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double
    }

    final class TieredAcuityPlanAuditAdjuster: AcuityPlanAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAcuityPlanAuditAdjuster: AcuityPlanAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleAcuityPlanAuditAdjuster: AcuityPlanAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AcuityPlanAuditWeightOffsetAdjuster: AcuityPlanAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class FlaggedAcuityPlanAuditAdjuster: AcuityPlanAuditModifier {
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

        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAcuityPlanAuditAdjuster: AcuityPlanAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan audit steps in order and keeps a trace of each.
    final class AcuityPlanAuditEngine {
        var steps: [any AcuityPlanAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanAudit) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanAuditModifier = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanAuditEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanAuditEngine {
        return AcuityPlanAuditEngine(
            steps: [
                TieredAcuityPlanAuditAdjuster(bounds: [7304.0, 7692.0], rates: [0.83, 0.88]),
                MinimumAcuityPlanAuditAdjuster(minimum: 22.0),
                TitleAcuityPlanAuditAdjuster(factors: ["east": 1.02, "west": 0.82, "south": 0.9]),
                AcuityPlanAuditWeightOffsetAdjuster(weight: 1.83),
                FlaggedAcuityPlanAuditAdjuster(flags: flags, flag: "acuity-plan-audit-default", percent: -7.8),
                CapAcuityPlanAuditAdjuster(cap: 14054.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 8655.8
        )
    }
}
