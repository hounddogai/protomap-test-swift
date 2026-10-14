import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered charge batch calculation.
    protocol ChargeBatchTieredChargeBatchAdjuster {
        func describe() -> String
        func adjust(_ item: TieredChargeBatch, value: Double) -> Double
    }

    final class RoundingTieredChargeBatchAdjuster: ChargeBatchTieredChargeBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredChargeBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTieredChargeBatchAdjuster: ChargeBatchTieredChargeBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredChargeBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredChargeBatchAdjuster: ChargeBatchTieredChargeBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredChargeBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered charge batch steps in order and keeps a trace of each.
    final class TieredChargeBatchEngine {
        var steps: [any ChargeBatchTieredChargeBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeBatchTieredChargeBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredChargeBatch) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeBatchTieredChargeBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredChargeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredChargeBatchEngine() -> TieredChargeBatchEngine {
        return TieredChargeBatchEngine(
            steps: [
                RoundingTieredChargeBatchAdjuster(step: 1.0),
                CapTieredChargeBatchAdjuster(cap: 42825.0),
                MinimumTieredChargeBatchAdjuster(minimum: 39.3),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 5877.0
        )
    }
}
