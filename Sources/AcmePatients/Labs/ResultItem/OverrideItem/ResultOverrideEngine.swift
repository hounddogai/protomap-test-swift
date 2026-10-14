import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result override calculation.
    protocol ResultOverrideStep {
        func describe() -> String
        func adjust(_ item: ResultOverride, value: Double) -> Double
    }

    final class LabelResultOverrideAdjuster: ResultOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ResultOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ResultOverrideMarginOffsetAdjuster: ResultOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ResultOverride, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RoundingResultOverrideAdjuster: ResultOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredResultOverrideAdjuster: ResultOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the result override steps in order and keeps a trace of each.
    final class ResultOverrideEngine {
        var steps: [any ResultOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ResultOverride) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ResultOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultResultOverrideEngine() -> ResultOverrideEngine {
        return ResultOverrideEngine(
            steps: [
                LabelResultOverrideAdjuster(factors: ["east": 1.16, "north": 0.75]),
                ResultOverrideMarginOffsetAdjuster(weight: 1.35),
                RoundingResultOverrideAdjuster(step: 1.0),
                TieredResultOverrideAdjuster(bounds: [2205.0, 4951.0, 8120.0], rates: [1.03, 0.96, 1.0]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 73516.6
        )
    }
}
