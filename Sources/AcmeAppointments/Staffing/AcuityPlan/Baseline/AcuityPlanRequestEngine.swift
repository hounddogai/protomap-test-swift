import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan request calculation.
    protocol AcuityPlanRequestModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanRequest, value: Double) -> Double
    }

    final class FlaggedAcuityPlanRequestAdjuster: AcuityPlanRequestModifier {
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

        func adjust(_ item: AcuityPlanRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AcuityPlanRequestPriorityOffsetAdjuster: AcuityPlanRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: AcuityPlanRequest, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class RoundingAcuityPlanRequestAdjuster: AcuityPlanRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the acuity plan request steps in order and keeps a trace of each.
    final class AcuityPlanRequestEngine {
        var steps: [any AcuityPlanRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanRequest) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanRequestModifier = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanRequestEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanRequestEngine {
        return AcuityPlanRequestEngine(
            steps: [
                FlaggedAcuityPlanRequestAdjuster(flags: flags, flag: "acuity-plan-request-batched", percent: -1.2),
                AcuityPlanRequestPriorityOffsetAdjuster(weight: 0.44),
                RoundingAcuityPlanRequestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 70780.3
        )
    }
}
