import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan summary calculation.
    protocol DischargePlanSummaryStep {
        func describe() -> String
        func adjust(_ item: DischargePlanSummary, value: Double) -> Double
    }

    final class CountryDischargePlanSummaryAdjuster: DischargePlanSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DischargePlanSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DischargePlanSummaryQuantityOffsetAdjuster: DischargePlanSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DischargePlanSummary, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RoundingDischargePlanSummaryAdjuster: DischargePlanSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDischargePlanSummaryAdjuster: DischargePlanSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDischargePlanSummaryAdjuster: DischargePlanSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the discharge plan summary steps in order and keeps a trace of each.
    final class DischargePlanSummaryEngine {
        var steps: [any DischargePlanSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanSummary) -> Double {
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

        func evaluateAll(_ items: [DischargePlanSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanSummaryEngine() -> DischargePlanSummaryEngine {
        return DischargePlanSummaryEngine(
            steps: [
                CountryDischargePlanSummaryAdjuster(factors: ["west": 1.25, "online": 0.72]),
                DischargePlanSummaryQuantityOffsetAdjuster(weight: 0.77),
                RoundingDischargePlanSummaryAdjuster(step: 0.25),
                CapDischargePlanSummaryAdjuster(cap: 30858.0),
                PercentDischargePlanSummaryAdjuster(percent: 4.9),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 18564.6
        )
    }
}
