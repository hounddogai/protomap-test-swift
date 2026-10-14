import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan draft calculation.
    protocol AcuityPlanDraftFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanDraft, value: Double) -> Double
    }

    final class PercentAcuityPlanDraftAdjuster: AcuityPlanDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAcuityPlanDraftAdjuster: AcuityPlanDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAcuityPlanDraftAdjuster: AcuityPlanDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAcuityPlanDraftAdjuster: AcuityPlanDraftFactor {
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

        func adjust(_ item: AcuityPlanDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAcuityPlanDraftAdjuster: AcuityPlanDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the acuity plan draft steps in order and keeps a trace of each.
    final class AcuityPlanDraftEngine {
        var steps: [any AcuityPlanDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanDraft) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanDraftFactor = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanDraftEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanDraftEngine {
        return AcuityPlanDraftEngine(
            steps: [
                PercentAcuityPlanDraftAdjuster(percent: -2.4),
                TieredAcuityPlanDraftAdjuster(
                    bounds: [2595.0, 5344.0, 6231.0, 9830.0],
                    rates: [1.07, 0.81, 0.81, 1.19]
                ),
                MinimumAcuityPlanDraftAdjuster(minimum: 5.0),
                FlaggedAcuityPlanDraftAdjuster(flags: flags, flag: "acuity-plan-draft-global", percent: 8.6),
                RoundingAcuityPlanDraftAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 40992.3
        )
    }
}
