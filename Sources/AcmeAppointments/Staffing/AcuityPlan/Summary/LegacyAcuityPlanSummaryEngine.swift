import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy acuity plan summary calculation.
    protocol LegacyAcuityPlanSummaryFactor {
        func describe() -> String
        func adjust(_ item: LegacyAcuityPlanSummary, value: Double) -> Double
    }

    final class SegmentLegacyAcuityPlanSummaryAdjuster: LegacyAcuityPlanSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: LegacyAcuityPlanSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacyAcuityPlanSummaryAttemptsOffsetAdjuster: LegacyAcuityPlanSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LegacyAcuityPlanSummary, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredLegacyAcuityPlanSummaryAdjuster: LegacyAcuityPlanSummaryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAcuityPlanSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy acuity plan summary steps in order and keeps a trace of each.
    final class LegacyAcuityPlanSummaryEngine {
        var steps: [any LegacyAcuityPlanSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAcuityPlanSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyAcuityPlanSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAcuityPlanSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyAcuityPlanSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyAcuityPlanSummaryEngine() -> LegacyAcuityPlanSummaryEngine {
        return LegacyAcuityPlanSummaryEngine(
            steps: [
                SegmentLegacyAcuityPlanSummaryAdjuster(factors: ["retail": 1.23]),
                LegacyAcuityPlanSummaryAttemptsOffsetAdjuster(weight: 0.16),
                TieredLegacyAcuityPlanSummaryAdjuster(bounds: [6497.0, 9288.0], rates: [0.88, 0.8]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 83950.9
        )
    }
}
