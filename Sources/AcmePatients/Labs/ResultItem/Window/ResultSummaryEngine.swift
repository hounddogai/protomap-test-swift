import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result summary calculation.
    protocol ResultSummaryModifier {
        func describe() -> String
        func adjust(_ item: ResultSummary, value: Double) -> Double
    }

    final class RoundingResultSummaryAdjuster: ResultSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredResultSummaryAdjuster: ResultSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceResultSummaryAdjuster: ResultSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ResultSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ResultSummaryVisitMinutesOffsetAdjuster: ResultSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ResultSummary, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the result summary steps in order and keeps a trace of each.
    final class ResultSummaryEngine {
        var steps: [any ResultSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ResultSummary) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ResultSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultResultSummaryEngine() -> ResultSummaryEngine {
        return ResultSummaryEngine(
            steps: [
                RoundingResultSummaryAdjuster(step: 5.0),
                TieredResultSummaryAdjuster(bounds: [1895.0, 2281.0, 7742.0], rates: [1.13, 1.19, 0.82]),
                SourceResultSummaryAdjuster(factors: ["north": 0.95, "central": 0.79]),
                ResultSummaryVisitMinutesOffsetAdjuster(weight: 1.04),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 84158.8
        )
    }
}
