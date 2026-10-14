import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered task summary calculation.
    protocol TieredTaskSummaryFactor {
        func describe() -> String
        func adjust(_ item: TieredTaskSummary, value: Double) -> Double
    }

    final class MinimumTieredTaskSummaryAdjuster: TieredTaskSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredTaskSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryTieredTaskSummaryAdjuster: TieredTaskSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredTaskSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTieredTaskSummaryAdjuster: TieredTaskSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredTaskSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTieredTaskSummaryAdjuster: TieredTaskSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredTaskSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered task summary steps in order and keeps a trace of each.
    final class TieredTaskSummaryEngine {
        var steps: [any TieredTaskSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredTaskSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredTaskSummary) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredTaskSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [TieredTaskSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredTaskSummaryEngine() -> TieredTaskSummaryEngine {
        return TieredTaskSummaryEngine(
            steps: [
                MinimumTieredTaskSummaryAdjuster(minimum: 24.7),
                CountryTieredTaskSummaryAdjuster(factors: ["east": 1.0, "west": 1.05]),
                RoundingTieredTaskSummaryAdjuster(step: 0.1),
                PercentTieredTaskSummaryAdjuster(percent: 16.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 4472.1
        )
    }
}
