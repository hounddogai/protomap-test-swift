import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan summary calculation.
    protocol AcuityPlanSummaryFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanSummary, value: Double) -> Double
    }

    final class MinimumAcuityPlanSummaryAdjuster: AcuityPlanSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryAcuityPlanSummaryAdjuster: AcuityPlanSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AcuityPlanSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AcuityPlanSummaryGraceDaysOffsetAdjuster: AcuityPlanSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: AcuityPlanSummary, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredAcuityPlanSummaryAdjuster: AcuityPlanSummaryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAcuityPlanSummaryAdjuster: AcuityPlanSummaryFactor {
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

        func adjust(_ item: AcuityPlanSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the acuity plan summary steps in order and keeps a trace of each.
    final class AcuityPlanSummaryEngine {
        var steps: [any AcuityPlanSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanSummary) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanSummaryEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanSummaryEngine {
        return AcuityPlanSummaryEngine(
            steps: [
                MinimumAcuityPlanSummaryAdjuster(minimum: 12.4),
                CategoryAcuityPlanSummaryAdjuster(factors: ["east": 1.06, "retail": 1.11, "north": 1.04]),
                AcuityPlanSummaryGraceDaysOffsetAdjuster(weight: 0.29),
                TieredAcuityPlanSummaryAdjuster(bounds: [482.0, 7167.0], rates: [1.1, 0.97]),
                FlaggedAcuityPlanSummaryAdjuster(flags: flags, flag: "acuity-plan-summary-rolling", percent: 9.2),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 64924.2
        )
    }
}
