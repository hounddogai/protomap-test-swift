import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim summary calculation.
    protocol ClaimSummaryModifier {
        func describe() -> String
        func adjust(_ item: ClaimSummary, value: Double) -> Double
    }

    final class PercentClaimSummaryAdjuster: ClaimSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelClaimSummaryAdjuster: ClaimSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClaimSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingClaimSummaryAdjuster: ClaimSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim summary steps in order and keeps a trace of each.
    final class ClaimSummaryEngine {
        var steps: [any ClaimSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimSummary) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [ClaimSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimSummaryEngine() -> ClaimSummaryEngine {
        return ClaimSummaryEngine(
            steps: [
                PercentClaimSummaryAdjuster(percent: 2.9),
                LabelClaimSummaryAdjuster(factors: ["online": 1.22, "north": 0.87]),
                RoundingClaimSummaryAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 98412.0
        )
    }
}
