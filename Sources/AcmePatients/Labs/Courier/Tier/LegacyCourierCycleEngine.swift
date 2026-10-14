import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy courier cycle calculation.
    protocol LegacyCourierCycleStep {
        func describe() -> String
        func adjust(_ item: LegacyCourierCycle, value: Double) -> Double
    }

    final class MinimumLegacyCourierCycleAdjuster: LegacyCourierCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCourierCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LegacyCourierCycleBatchSizeOffsetAdjuster: LegacyCourierCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: LegacyCourierCycle, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredLegacyCourierCycleAdjuster: LegacyCourierCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCourierCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy courier cycle steps in order and keeps a trace of each.
    final class LegacyCourierCycleEngine {
        var steps: [any LegacyCourierCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCourierCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyCourierCycle) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCourierCycleStep = steps[index]
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

        func evaluateAll(_ items: [LegacyCourierCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyCourierCycleEngine() -> LegacyCourierCycleEngine {
        return LegacyCourierCycleEngine(
            steps: [
                MinimumLegacyCourierCycleAdjuster(minimum: 11.3),
                LegacyCourierCycleBatchSizeOffsetAdjuster(weight: 0.85),
                TieredLegacyCourierCycleAdjuster(
                    bounds: [3455.0, 6158.0, 8356.0, 9921.0],
                    rates: [0.9, 1.17, 1.08, 1.17]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 11534.9
        )
    }
}
