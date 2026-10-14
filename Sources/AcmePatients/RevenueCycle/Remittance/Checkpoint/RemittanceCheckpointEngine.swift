import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance checkpoint calculation.
    protocol RemittanceCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceCheckpoint, value: Double) -> Double
    }

    final class CapRemittanceCheckpointAdjuster: RemittanceCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRemittanceCheckpointAdjuster: RemittanceCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRemittanceCheckpointAdjuster: RemittanceCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RemittanceCheckpointAttemptsOffsetAdjuster: RemittanceCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RemittanceCheckpoint, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the remittance checkpoint steps in order and keeps a trace of each.
    final class RemittanceCheckpointEngine {
        var steps: [any RemittanceCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceCheckpoint) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [RemittanceCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceCheckpointEngine() -> RemittanceCheckpointEngine {
        return RemittanceCheckpointEngine(
            steps: [
                CapRemittanceCheckpointAdjuster(cap: 17533.0),
                TieredRemittanceCheckpointAdjuster(bounds: [286.0, 3723.0, 9329.0], rates: [0.87, 1.09, 1.04]),
                PercentRemittanceCheckpointAdjuster(percent: -13.8),
                RemittanceCheckpointAttemptsOffsetAdjuster(weight: 0.89),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 45926.7
        )
    }
}
