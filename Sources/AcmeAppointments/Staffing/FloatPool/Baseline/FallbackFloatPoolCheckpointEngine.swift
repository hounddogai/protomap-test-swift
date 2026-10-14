import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback float pool checkpoint calculation.
    protocol FallbackFloatPoolCheckpointStep {
        func describe() -> String
        func adjust(_ item: FallbackFloatPoolCheckpoint, value: Double) -> Double
    }

    final class PercentFallbackFloatPoolCheckpointAdjuster: FallbackFloatPoolCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackFloatPoolCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackFloatPoolCheckpointAdjuster: FallbackFloatPoolCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackFloatPoolCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackFloatPoolCheckpointAdjuster: FallbackFloatPoolCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackFloatPoolCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback float pool checkpoint steps in order and keeps a trace of each.
    final class FallbackFloatPoolCheckpointEngine {
        var steps: [any FallbackFloatPoolCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFloatPoolCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackFloatPoolCheckpoint) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackFloatPoolCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [FallbackFloatPoolCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackFloatPoolCheckpointEngine() -> FallbackFloatPoolCheckpointEngine {
        return FallbackFloatPoolCheckpointEngine(
            steps: [
                PercentFallbackFloatPoolCheckpointAdjuster(percent: -7.0),
                TieredFallbackFloatPoolCheckpointAdjuster(bounds: [1521.0, 6992.0, 8542.0], rates: [1.06, 0.84, 0.88]),
                CapFallbackFloatPoolCheckpointAdjuster(cap: 1169.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 97597.3
        )
    }
}
