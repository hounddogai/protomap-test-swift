import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan segment calculation.
    protocol DischargePlanSegmentFactor {
        func describe() -> String
        func adjust(_ item: DischargePlanSegment, value: Double) -> Double
    }

    final class CapDischargePlanSegmentAdjuster: DischargePlanSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDischargePlanSegmentAdjuster: DischargePlanSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDischargePlanSegmentAdjuster: DischargePlanSegmentFactor {
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

        func adjust(_ item: DischargePlanSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the discharge plan segment steps in order and keeps a trace of each.
    final class DischargePlanSegmentEngine {
        var steps: [any DischargePlanSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DischargePlanSegment) -> Double {
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

        func evaluateAll(_ items: [DischargePlanSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDischargePlanSegmentEngine(_ flags: Kit.Flags.Registry) -> DischargePlanSegmentEngine {
        return DischargePlanSegmentEngine(
            steps: [
                CapDischargePlanSegmentAdjuster(cap: 31546.0),
                PercentDischargePlanSegmentAdjuster(percent: 22.5),
                FlaggedDischargePlanSegmentAdjuster(
                    flags: flags,
                    flag: "discharge-plan-segment-primary",
                    percent: 2.2
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 10393.6
        )
    }
}
