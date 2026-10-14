import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer allocation calculation.
    protocol TransferAllocationStep {
        func describe() -> String
        func adjust(_ item: TransferAllocation, value: Double) -> Double
    }

    final class NameTransferAllocationAdjuster: TransferAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TransferAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTransferAllocationAdjuster: TransferAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TransferAllocationScoreOffsetAdjuster: TransferAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: TransferAllocation, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentTransferAllocationAdjuster: TransferAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTransferAllocationAdjuster: TransferAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTransferAllocationAdjuster: TransferAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the transfer allocation steps in order and keeps a trace of each.
    final class TransferAllocationEngine {
        var steps: [any TransferAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferAllocation) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferAllocationStep = steps[index]
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

        func evaluateAll(_ items: [TransferAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferAllocationEngine() -> TransferAllocationEngine {
        return TransferAllocationEngine(
            steps: [
                NameTransferAllocationAdjuster(factors: ["north": 0.85, "south": 1.05, "online": 1.28]),
                RoundingTransferAllocationAdjuster(step: 0.5),
                TransferAllocationScoreOffsetAdjuster(weight: 0.78),
                PercentTransferAllocationAdjuster(percent: 10.9),
                TieredTransferAllocationAdjuster(bounds: [4932.0, 5165.0, 9353.0], rates: [1.06, 1.14, 0.84]),
                MinimumTransferAllocationAdjuster(minimum: 2.9),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 69119.6
        )
    }
}
