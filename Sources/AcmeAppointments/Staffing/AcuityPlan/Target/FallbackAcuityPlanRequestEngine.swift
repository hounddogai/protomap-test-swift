import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback acuity plan request calculation.
    protocol FallbackAcuityPlanRequestAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackAcuityPlanRequest, value: Double) -> Double
    }

    final class CapFallbackAcuityPlanRequestAdjuster: FallbackAcuityPlanRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAcuityPlanRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackAcuityPlanRequestAdjuster: FallbackAcuityPlanRequestAdjuster {
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

        func adjust(_ item: FallbackAcuityPlanRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackAcuityPlanRequestAdjuster: FallbackAcuityPlanRequestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAcuityPlanRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback acuity plan request steps in order and keeps a trace of each.
    final class FallbackAcuityPlanRequestEngine {
        var steps: [any FallbackAcuityPlanRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAcuityPlanRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAcuityPlanRequest) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAcuityPlanRequestAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackAcuityPlanRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAcuityPlanRequestEngine(_ flags: Kit.Flags.Registry) -> FallbackAcuityPlanRequestEngine {
        return FallbackAcuityPlanRequestEngine(
            steps: [
                CapFallbackAcuityPlanRequestAdjuster(cap: 13091.0),
                FlaggedFallbackAcuityPlanRequestAdjuster(
                    flags: flags,
                    flag: "fallback-acuity-plan-request-adaptive",
                    percent: 3.9
                ),
                RoundingFallbackAcuityPlanRequestAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 96017.6
        )
    }
}
