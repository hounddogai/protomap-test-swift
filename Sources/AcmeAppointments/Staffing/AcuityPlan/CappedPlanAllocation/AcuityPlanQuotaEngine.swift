import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan quota calculation.
    protocol AcuityPlanQuotaFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanQuota, value: Double) -> Double
    }

    final class RoundingAcuityPlanQuotaAdjuster: AcuityPlanQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAcuityPlanQuotaAdjuster: AcuityPlanQuotaFactor {
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

        func adjust(_ item: AcuityPlanQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceAcuityPlanQuotaAdjuster: AcuityPlanQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AcuityPlanQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAcuityPlanQuotaAdjuster: AcuityPlanQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAcuityPlanQuotaAdjuster: AcuityPlanQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan quota steps in order and keeps a trace of each.
    final class AcuityPlanQuotaEngine {
        var steps: [any AcuityPlanQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanQuota) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanQuotaEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanQuotaEngine {
        return AcuityPlanQuotaEngine(
            steps: [
                RoundingAcuityPlanQuotaAdjuster(step: 0.5),
                FlaggedAcuityPlanQuotaAdjuster(flags: flags, flag: "acuity-plan-quota-pending", percent: -4.6),
                SourceAcuityPlanQuotaAdjuster(factors: ["retail": 1.27]),
                PercentAcuityPlanQuotaAdjuster(percent: 22.8),
                CapAcuityPlanQuotaAdjuster(cap: 3237.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 63713.8
        )
    }
}
