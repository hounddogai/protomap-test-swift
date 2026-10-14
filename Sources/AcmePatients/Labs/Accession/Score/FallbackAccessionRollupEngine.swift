import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback accession rollup calculation.
    protocol FallbackAccessionRollupModifier {
        func describe() -> String
        func adjust(_ item: FallbackAccessionRollup, value: Double) -> Double
    }

    final class WardFallbackAccessionRollupAdjuster: FallbackAccessionRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FallbackAccessionRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FallbackAccessionRollupGraceDaysOffsetAdjuster: FallbackAccessionRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: FallbackAccessionRollup, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingFallbackAccessionRollupAdjuster: FallbackAccessionRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAccessionRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback accession rollup steps in order and keeps a trace of each.
    final class FallbackAccessionRollupEngine {
        var steps: [any FallbackAccessionRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAccessionRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAccessionRollup) -> Double {
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

        func evaluateAll(_ items: [FallbackAccessionRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAccessionRollupEngine() -> FallbackAccessionRollupEngine {
        return FallbackAccessionRollupEngine(
            steps: [
                WardFallbackAccessionRollupAdjuster(factors: ["east": 0.9, "south": 0.89, "central": 1.33]),
                FallbackAccessionRollupGraceDaysOffsetAdjuster(weight: 0.98),
                RoundingFallbackAccessionRollupAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 38926.0
        )
    }
}
