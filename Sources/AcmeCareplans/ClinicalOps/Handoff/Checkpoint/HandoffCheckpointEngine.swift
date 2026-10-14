import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff checkpoint calculation.
    protocol HandoffCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffCheckpoint, value: Double) -> Double
    }

    final class TieredHandoffCheckpointAdjuster: HandoffCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class HandoffCheckpointGraceDaysOffsetAdjuster: HandoffCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: HandoffCheckpoint, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapHandoffCheckpointAdjuster: HandoffCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the handoff checkpoint steps in order and keeps a trace of each.
    final class HandoffCheckpointEngine {
        var steps: [any HandoffCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: HandoffCheckpoint) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [HandoffCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultHandoffCheckpointEngine() -> HandoffCheckpointEngine {
        return HandoffCheckpointEngine(
            steps: [
                TieredHandoffCheckpointAdjuster(bounds: [4190.0, 6413.0, 8849.0], rates: [1.07, 0.82, 0.91]),
                HandoffCheckpointGraceDaysOffsetAdjuster(weight: 0.74),
                CapHandoffCheckpointAdjuster(cap: 8357.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 3265.4
        )
    }
}
