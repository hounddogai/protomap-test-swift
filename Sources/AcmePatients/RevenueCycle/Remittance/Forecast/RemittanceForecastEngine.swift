import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance forecast calculation.
    protocol RemittanceForecastFactor {
        func describe() -> String
        func adjust(_ item: RemittanceForecast, value: Double) -> Double
    }

    final class MinimumRemittanceForecastAdjuster: RemittanceForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RemittanceForecastBatchSizeOffsetAdjuster: RemittanceForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: RemittanceForecast, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class UnitRemittanceForecastAdjuster: RemittanceForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RemittanceForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the remittance forecast steps in order and keeps a trace of each.
    final class RemittanceForecastEngine {
        var steps: [any RemittanceForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceForecast) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceForecastFactor = steps[index]
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

        func evaluateAll(_ items: [RemittanceForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceForecastEngine() -> RemittanceForecastEngine {
        return RemittanceForecastEngine(
            steps: [
                MinimumRemittanceForecastAdjuster(minimum: 7.8),
                RemittanceForecastBatchSizeOffsetAdjuster(weight: 0.45),
                UnitRemittanceForecastAdjuster(factors: ["online": 0.95, "south": 0.79]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 15609.7
        )
    }
}
