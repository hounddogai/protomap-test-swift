import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted order set summary calculation.
    protocol WeightedOrderSetSummaryStep {
        func describe() -> String
        func adjust(_ item: WeightedOrderSetSummary, value: Double) -> Double
    }

    final class WeightedOrderSetSummaryVersionOffsetAdjuster: WeightedOrderSetSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: WeightedOrderSetSummary, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class MinimumWeightedOrderSetSummaryAdjuster: WeightedOrderSetSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedOrderSetSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedOrderSetSummaryAdjuster: WeightedOrderSetSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedOrderSetSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted order set summary steps in order and keeps a trace of each.
    final class WeightedOrderSetSummaryEngine {
        var steps: [any WeightedOrderSetSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOrderSetSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedOrderSetSummary) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [WeightedOrderSetSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedOrderSetSummaryEngine() -> WeightedOrderSetSummaryEngine {
        return WeightedOrderSetSummaryEngine(
            steps: [
                WeightedOrderSetSummaryVersionOffsetAdjuster(weight: 0.63),
                MinimumWeightedOrderSetSummaryAdjuster(minimum: 27.3),
                RoundingWeightedOrderSetSummaryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 94018.9
        )
    }
}
