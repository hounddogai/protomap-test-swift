import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan item calculation.
    protocol AcuityPlanItemFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanItem, value: Double) -> Double
    }

    final class MinimumAcuityPlanItemAdjuster: AcuityPlanItemFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanItem, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAcuityPlanItemAdjuster: AcuityPlanItemFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanItem, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAcuityPlanItemAdjuster: AcuityPlanItemFactor {
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

        func adjust(_ item: AcuityPlanItem, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentAcuityPlanItemAdjuster: AcuityPlanItemFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AcuityPlanItem, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the acuity plan item steps in order and keeps a trace of each.
    final class AcuityPlanItemEngine {
        var steps: [any AcuityPlanItemFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanItemFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AcuityPlanItem) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanItemFactor = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanItemEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanItemEngine {
        return AcuityPlanItemEngine(
            steps: [
                MinimumAcuityPlanItemAdjuster(minimum: 39.0),
                PercentAcuityPlanItemAdjuster(percent: -4.8),
                FlaggedAcuityPlanItemAdjuster(flags: flags, flag: "acuity-plan-item-lenient", percent: 3.3),
                SegmentAcuityPlanItemAdjuster(factors: ["west": 1.21, "online": 1.39]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 86225.7
        )
    }
}
