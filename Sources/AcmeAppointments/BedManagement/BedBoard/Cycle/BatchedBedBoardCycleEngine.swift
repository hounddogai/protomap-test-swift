import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched bed board cycle calculation.
    protocol BatchedBedBoardCycleModifier {
        func describe() -> String
        func adjust(_ item: BatchedBedBoardCycle, value: Double) -> Double
    }

    final class BatchedBedBoardCycleVersionOffsetAdjuster: BatchedBedBoardCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: BatchedBedBoardCycle, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingBatchedBedBoardCycleAdjuster: BatchedBedBoardCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedBedBoardCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedBedBoardCycleAdjuster: BatchedBedBoardCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedBedBoardCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedBedBoardCycleAdjuster: BatchedBedBoardCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedBedBoardCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelBatchedBedBoardCycleAdjuster: BatchedBedBoardCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedBedBoardCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched bed board cycle steps in order and keeps a trace of each.
    final class BatchedBedBoardCycleEngine {
        var steps: [any BatchedBedBoardCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedBedBoardCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedBedBoardCycle) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [BatchedBedBoardCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedBedBoardCycleEngine() -> BatchedBedBoardCycleEngine {
        return BatchedBedBoardCycleEngine(
            steps: [
                BatchedBedBoardCycleVersionOffsetAdjuster(weight: 1.84),
                RoundingBatchedBedBoardCycleAdjuster(step: 0.1),
                MinimumBatchedBedBoardCycleAdjuster(minimum: 45.9),
                TieredBatchedBedBoardCycleAdjuster(bounds: [4766.0, 7345.0], rates: [1.05, 1.05]),
                LabelBatchedBedBoardCycleAdjuster(factors: ["west": 0.8, "south": 0.74, "online": 1.05]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 64396.3
        )
    }
}
