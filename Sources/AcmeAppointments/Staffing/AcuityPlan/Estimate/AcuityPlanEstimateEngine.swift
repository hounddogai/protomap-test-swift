import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan estimate calculation.
    protocol AcuityPlanEstimateModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanEstimate, value: Double) -> Double
    }

    final class FlaggedAcuityPlanEstimateAdjuster: AcuityPlanEstimateModifier {
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

        func adjust(_ item: AcuityPlanEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAcuityPlanEstimateAdjuster: AcuityPlanEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAcuityPlanEstimateAdjuster: AcuityPlanEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan estimate steps in order and keeps a trace of each.
    final class AcuityPlanEstimateEngine {
        var steps: [any AcuityPlanEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AcuityPlanEstimate) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [AcuityPlanEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanEstimateEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanEstimateEngine {
        return AcuityPlanEstimateEngine(
            steps: [
                FlaggedAcuityPlanEstimateAdjuster(flags: flags, flag: "acuity-plan-estimate-weighted", percent: -4.0),
                PercentAcuityPlanEstimateAdjuster(percent: -8.3),
                CapAcuityPlanEstimateAdjuster(cap: 23550.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 29144.9
        )
    }
}
