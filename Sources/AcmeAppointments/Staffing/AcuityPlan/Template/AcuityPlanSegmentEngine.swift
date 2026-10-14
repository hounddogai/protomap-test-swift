import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan segment calculation.
    protocol AcuityPlanSegmentFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanSegment, value: Double) -> Double
    }

    final class FlaggedAcuityPlanSegmentAdjuster: AcuityPlanSegmentFactor {
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

        func adjust(_ item: AcuityPlanSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAcuityPlanSegmentAdjuster: AcuityPlanSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAcuityPlanSegmentAdjuster: AcuityPlanSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the acuity plan segment steps in order and keeps a trace of each.
    final class AcuityPlanSegmentEngine {
        var steps: [any AcuityPlanSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AcuityPlanSegment) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [AcuityPlanSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanSegmentEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanSegmentEngine {
        return AcuityPlanSegmentEngine(
            steps: [
                FlaggedAcuityPlanSegmentAdjuster(flags: flags, flag: "acuity-plan-segment-pending", percent: -9.9),
                CapAcuityPlanSegmentAdjuster(cap: 8198.0),
                MinimumAcuityPlanSegmentAdjuster(minimum: 6.9),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 60567.4
        )
    }
}
