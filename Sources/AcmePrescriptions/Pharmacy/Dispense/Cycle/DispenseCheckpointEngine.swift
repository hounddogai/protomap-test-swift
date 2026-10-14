import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense checkpoint calculation.
    protocol DispenseCheckpointStep {
        func describe() -> String
        func adjust(_ item: DispenseCheckpoint, value: Double) -> Double
    }

    final class RoundingDispenseCheckpointAdjuster: DispenseCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDispenseCheckpointAdjuster: DispenseCheckpointStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: DispenseCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDispenseCheckpointAdjuster: DispenseCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the dispense checkpoint steps in order and keeps a trace of each.
    final class DispenseCheckpointEngine {
        var steps: [any DispenseCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseCheckpoint) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [DispenseCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseCheckpointEngine(_ flags: Kit.Flags.Registry) -> DispenseCheckpointEngine {
        return DispenseCheckpointEngine(
            steps: [
                RoundingDispenseCheckpointAdjuster(step: 0.25),
                FlaggedDispenseCheckpointAdjuster(flags: flags, flag: "dispense-checkpoint-legacy", percent: 6.3),
                TieredDispenseCheckpointAdjuster(bounds: [3086.0, 6837.0, 9992.0], rates: [0.85, 1.06, 0.81]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 46734.0
        )
    }
}
