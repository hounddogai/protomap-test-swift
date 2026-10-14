import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped care protocol rollup calculation.
    protocol CappedCareProtocolRollupStep {
        func describe() -> String
        func adjust(_ item: CappedCareProtocolRollup, value: Double) -> Double
    }

    final class TieredCappedCareProtocolRollupAdjuster: CappedCareProtocolRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCareProtocolRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedCareProtocolRollupFloorValueOffsetAdjuster: CappedCareProtocolRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: CappedCareProtocolRollup, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CapCappedCareProtocolRollupAdjuster: CappedCareProtocolRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCareProtocolRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCappedCareProtocolRollupAdjuster: CappedCareProtocolRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareProtocolRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCappedCareProtocolRollupAdjuster: CappedCareProtocolRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCareProtocolRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped care protocol rollup steps in order and keeps a trace of each.
    final class CappedCareProtocolRollupEngine {
        var steps: [any CappedCareProtocolRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareProtocolRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedCareProtocolRollup) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCareProtocolRollupStep = steps[index]
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

        func evaluateAll(_ items: [CappedCareProtocolRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedCareProtocolRollupEngine() -> CappedCareProtocolRollupEngine {
        return CappedCareProtocolRollupEngine(
            steps: [
                TieredCappedCareProtocolRollupAdjuster(
                    bounds: [1937.0, 2077.0, 5900.0, 7065.0],
                    rates: [0.87, 1.03, 1.04, 0.87]
                ),
                CappedCareProtocolRollupFloorValueOffsetAdjuster(weight: 1.8),
                CapCappedCareProtocolRollupAdjuster(cap: 34939.0),
                RoundingCappedCareProtocolRollupAdjuster(step: 0.05),
                MinimumCappedCareProtocolRollupAdjuster(minimum: 17.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 55575.9
        )
    }
}
