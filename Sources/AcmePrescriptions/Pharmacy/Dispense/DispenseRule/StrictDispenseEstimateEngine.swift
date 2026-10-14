import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict dispense estimate calculation.
    protocol StrictDispenseEstimateFactor {
        func describe() -> String
        func adjust(_ item: StrictDispenseEstimate, value: Double) -> Double
    }

    final class StrictDispenseEstimateExpiresAtOffsetAdjuster: StrictDispenseEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: StrictDispenseEstimate, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class NameStrictDispenseEstimateAdjuster: StrictDispenseEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictDispenseEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictDispenseEstimateAdjuster: StrictDispenseEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictDispenseEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStrictDispenseEstimateAdjuster: StrictDispenseEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictDispenseEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict dispense estimate steps in order and keeps a trace of each.
    final class StrictDispenseEstimateEngine {
        var steps: [any StrictDispenseEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictDispenseEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictDispenseEstimate) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictDispenseEstimateFactor = steps[index]
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

        func evaluateAll(_ items: [StrictDispenseEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictDispenseEstimateEngine() -> StrictDispenseEstimateEngine {
        return StrictDispenseEstimateEngine(
            steps: [
                StrictDispenseEstimateExpiresAtOffsetAdjuster(weight: 1.74),
                NameStrictDispenseEstimateAdjuster(factors: ["online": 1.05, "south": 0.92]),
                RoundingStrictDispenseEstimateAdjuster(step: 0.1),
                PercentStrictDispenseEstimateAdjuster(percent: -0.7),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 94827.5
        )
    }
}
