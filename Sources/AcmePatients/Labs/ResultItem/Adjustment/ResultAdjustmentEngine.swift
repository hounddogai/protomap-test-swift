import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result adjustment calculation.
    protocol ResultAdjustmentStep {
        func describe() -> String
        func adjust(_ item: ResultAdjustment, value: Double) -> Double
    }

    final class RoundingResultAdjustmentAdjuster: ResultAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ResultAdjustmentLimitOffsetAdjuster: ResultAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ResultAdjustment, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumResultAdjustmentAdjuster: ResultAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the result adjustment steps in order and keeps a trace of each.
    final class ResultAdjustmentEngine {
        var steps: [any ResultAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultAdjustment) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ResultAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultAdjustmentEngine() -> ResultAdjustmentEngine {
        return ResultAdjustmentEngine(
            steps: [
                RoundingResultAdjustmentAdjuster(step: 1.0),
                ResultAdjustmentLimitOffsetAdjuster(weight: 1.22),
                MinimumResultAdjustmentAdjuster(minimum: 3.6),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 69095.3
        )
    }
}
