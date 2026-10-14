import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict overtime summary calculation.
    protocol StrictOvertimeSummaryStep {
        func describe() -> String
        func adjust(_ item: StrictOvertimeSummary, value: Double) -> Double
    }

    final class StrictOvertimeSummaryAmountOffsetAdjuster: StrictOvertimeSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: StrictOvertimeSummary, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumStrictOvertimeSummaryAdjuster: StrictOvertimeSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictOvertimeSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictOvertimeSummaryAdjuster: StrictOvertimeSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictOvertimeSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelStrictOvertimeSummaryAdjuster: StrictOvertimeSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictOvertimeSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict overtime summary steps in order and keeps a trace of each.
    final class StrictOvertimeSummaryEngine {
        var steps: [any StrictOvertimeSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictOvertimeSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictOvertimeSummary) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictOvertimeSummaryStep = steps[index]
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

        func evaluateAll(_ items: [StrictOvertimeSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictOvertimeSummaryEngine() -> StrictOvertimeSummaryEngine {
        return StrictOvertimeSummaryEngine(
            steps: [
                StrictOvertimeSummaryAmountOffsetAdjuster(weight: 0.54),
                MinimumStrictOvertimeSummaryAdjuster(minimum: 2.2),
                CapStrictOvertimeSummaryAdjuster(cap: 6026.0),
                LabelStrictOvertimeSummaryAdjuster(factors: ["south": 1.03]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 53325.9
        )
    }
}
