import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending consent form checkpoint calculation.
    protocol PendingConsentFormCheckpointStep {
        func describe() -> String
        func adjust(_ item: PendingConsentFormCheckpoint, value: Double) -> Double
    }

    final class MinimumPendingConsentFormCheckpointAdjuster: PendingConsentFormCheckpointStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingConsentFormCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPendingConsentFormCheckpointAdjuster: PendingConsentFormCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingConsentFormCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingConsentFormCheckpointAdjuster: PendingConsentFormCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingConsentFormCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending consent form checkpoint steps in order and keeps a trace of each.
    final class PendingConsentFormCheckpointEngine {
        var steps: [any PendingConsentFormCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingConsentFormCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingConsentFormCheckpoint) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [PendingConsentFormCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingConsentFormCheckpointEngine() -> PendingConsentFormCheckpointEngine {
        return PendingConsentFormCheckpointEngine(
            steps: [
                MinimumPendingConsentFormCheckpointAdjuster(minimum: 43.8),
                RoundingPendingConsentFormCheckpointAdjuster(step: 5.0),
                TieredPendingConsentFormCheckpointAdjuster(bounds: [6949.0, 9217.0], rates: [1.03, 1.04]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 96034.9
        )
    }
}
