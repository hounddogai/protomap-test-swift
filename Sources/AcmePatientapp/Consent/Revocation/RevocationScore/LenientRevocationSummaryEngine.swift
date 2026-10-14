import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient revocation summary calculation.
    protocol LenientRevocationSummaryStep {
        func describe() -> String
        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double
    }

    final class MinimumLenientRevocationSummaryAdjuster: LenientRevocationSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientRevocationSummaryAdjuster: LenientRevocationSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientRevocationSummaryAdjuster: LenientRevocationSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitLenientRevocationSummaryAdjuster: LenientRevocationSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientRevocationSummaryCostOffsetAdjuster: LenientRevocationSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentLenientRevocationSummaryAdjuster: LenientRevocationSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRevocationSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient revocation summary steps in order and keeps a trace of each.
    final class LenientRevocationSummaryEngine {
        var steps: [any LenientRevocationSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRevocationSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientRevocationSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientRevocationSummaryStep = steps[index]
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

        func evaluateAll(_ items: [LenientRevocationSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientRevocationSummaryEngine() -> LenientRevocationSummaryEngine {
        return LenientRevocationSummaryEngine(
            steps: [
                MinimumLenientRevocationSummaryAdjuster(minimum: 46.6),
                CapLenientRevocationSummaryAdjuster(cap: 16348.0),
                RoundingLenientRevocationSummaryAdjuster(step: 0.1),
                UnitLenientRevocationSummaryAdjuster(factors: ["south": 1.13, "north": 1.23, "east": 0.99]),
                LenientRevocationSummaryCostOffsetAdjuster(weight: 0.41),
                PercentLenientRevocationSummaryAdjuster(percent: 8.7),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 6123.0
        )
    }
}
