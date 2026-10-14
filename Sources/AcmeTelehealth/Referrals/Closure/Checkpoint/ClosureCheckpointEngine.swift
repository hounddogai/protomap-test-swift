import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure checkpoint calculation.
    protocol ClosureCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: ClosureCheckpoint, value: Double) -> Double
    }

    final class MinimumClosureCheckpointAdjuster: ClosureCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelClosureCheckpointAdjuster: ClosureCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClosureCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapClosureCheckpointAdjuster: ClosureCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredClosureCheckpointAdjuster: ClosureCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingClosureCheckpointAdjuster: ClosureCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure checkpoint steps in order and keeps a trace of each.
    final class ClosureCheckpointEngine {
        var steps: [any ClosureCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureCheckpoint) -> Double {
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

        func evaluateAll(_ items: [ClosureCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureCheckpointEngine() -> ClosureCheckpointEngine {
        return ClosureCheckpointEngine(
            steps: [
                MinimumClosureCheckpointAdjuster(minimum: 17.7),
                LabelClosureCheckpointAdjuster(factors: ["west": 0.83, "north": 0.93, "central": 1.24]),
                CapClosureCheckpointAdjuster(cap: 26328.0),
                TieredClosureCheckpointAdjuster(
                    bounds: [787.0, 1682.0, 2736.0, 7276.0],
                    rates: [0.91, 1.19, 1.18, 1.08]
                ),
                RoundingClosureCheckpointAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 88768.0
        )
    }
}
