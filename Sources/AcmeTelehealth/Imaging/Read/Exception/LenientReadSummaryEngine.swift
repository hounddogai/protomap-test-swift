import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient read summary calculation.
    protocol LenientReadSummaryModifier {
        func describe() -> String
        func adjust(_ item: LenientReadSummary, value: Double) -> Double
    }

    final class LabelLenientReadSummaryAdjuster: LenientReadSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientReadSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientReadSummaryAdjuster: LenientReadSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientReadSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientReadSummaryAdjuster: LenientReadSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientReadSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient read summary steps in order and keeps a trace of each.
    final class LenientReadSummaryEngine {
        var steps: [any LenientReadSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReadSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientReadSummary) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [LenientReadSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientReadSummaryEngine() -> LenientReadSummaryEngine {
        return LenientReadSummaryEngine(
            steps: [
                LabelLenientReadSummaryAdjuster(factors: ["central": 0.79, "south": 0.79, "north": 1.25]),
                MinimumLenientReadSummaryAdjuster(minimum: 10.1),
                RoundingLenientReadSummaryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 43227.8
        )
    }
}
