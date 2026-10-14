import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan rollup calculation.
    protocol AcuityPlanRollupAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanRollup, value: Double) -> Double
    }

    final class FlaggedAcuityPlanRollupAdjuster: AcuityPlanRollupAdjuster {
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

        func adjust(_ item: AcuityPlanRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityAcuityPlanRollupAdjuster: AcuityPlanRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: AcuityPlanRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAcuityPlanRollupAdjuster: AcuityPlanRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the acuity plan rollup steps in order and keeps a trace of each.
    final class AcuityPlanRollupEngine {
        var steps: [any AcuityPlanRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanRollup) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AcuityPlanRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanRollupEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanRollupEngine {
        return AcuityPlanRollupEngine(
            steps: [
                FlaggedAcuityPlanRollupAdjuster(flags: flags, flag: "acuity-plan-rollup-global", percent: -1.1),
                FacilityAcuityPlanRollupAdjuster(factors: ["online": 0.9]),
                CapAcuityPlanRollupAdjuster(cap: 7451.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 49365.7
        )
    }
}
