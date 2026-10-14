import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range summary calculation.
    protocol ReferenceRangeSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeSummary, value: Double) -> Double
    }

    final class RoundingReferenceRangeSummaryAdjuster: ReferenceRangeSummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferenceRangeSummaryAdjuster: ReferenceRangeSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelReferenceRangeSummaryAdjuster: ReferenceRangeSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ReferenceRangeSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapReferenceRangeSummaryAdjuster: ReferenceRangeSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReferenceRangeSummaryAdjuster: ReferenceRangeSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the reference range summary steps in order and keeps a trace of each.
    final class ReferenceRangeSummaryEngine {
        var steps: [any ReferenceRangeSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReferenceRangeSummary) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeSummaryEngine() -> ReferenceRangeSummaryEngine {
        return ReferenceRangeSummaryEngine(
            steps: [
                RoundingReferenceRangeSummaryAdjuster(step: 0.05),
                PercentReferenceRangeSummaryAdjuster(percent: 13.3),
                LabelReferenceRangeSummaryAdjuster(factors: ["central": 0.87]),
                CapReferenceRangeSummaryAdjuster(cap: 4735.0),
                TieredReferenceRangeSummaryAdjuster(bounds: [6449.0, 7933.0], rates: [1.2, 0.98]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 88346.5
        )
    }
}
