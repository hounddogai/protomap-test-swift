import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered priority summary calculation.
    protocol TieredPrioritySummaryModifier {
        func describe() -> String
        func adjust(_ item: TieredPrioritySummary, value: Double) -> Double
    }

    final class RegionTieredPrioritySummaryAdjuster: TieredPrioritySummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredPrioritySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredPrioritySummaryAdjuster: TieredPrioritySummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredPrioritySummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTieredPrioritySummaryAdjuster: TieredPrioritySummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredPrioritySummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered priority summary steps in order and keeps a trace of each.
    final class TieredPrioritySummaryEngine {
        var steps: [any TieredPrioritySummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredPrioritySummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredPrioritySummary) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredPrioritySummaryModifier = steps[index]
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

        func evaluateAll(_ items: [TieredPrioritySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredPrioritySummaryEngine() -> TieredPrioritySummaryEngine {
        return TieredPrioritySummaryEngine(
            steps: [
                RegionTieredPrioritySummaryAdjuster(factors: ["central": 1.16]),
                MinimumTieredPrioritySummaryAdjuster(minimum: 27.5),
                RoundingTieredPrioritySummaryAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 84677.0
        )
    }
}
