import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending outreach checkpoint calculation.
    protocol PendingOutreachCheckpointFactor {
        func describe() -> String
        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double
    }

    final class RoundingPendingOutreachCheckpointAdjuster: PendingOutreachCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingOutreachCheckpointAdjuster: PendingOutreachCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPendingOutreachCheckpointAdjuster: PendingOutreachCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryPendingOutreachCheckpointAdjuster: PendingOutreachCheckpointFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingOutreachCheckpointAdjuster: PendingOutreachCheckpointFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingOutreachCheckpointVisitMinutesOffsetAdjuster: PendingOutreachCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: PendingOutreachCheckpoint, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the pending outreach checkpoint steps in order and keeps a trace of each.
    final class PendingOutreachCheckpointEngine {
        var steps: [any PendingOutreachCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingOutreachCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingOutreachCheckpoint) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingOutreachCheckpointFactor = steps[index]
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

        func evaluateAll(_ items: [PendingOutreachCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingOutreachCheckpointEngine() -> PendingOutreachCheckpointEngine {
        return PendingOutreachCheckpointEngine(
            steps: [
                RoundingPendingOutreachCheckpointAdjuster(step: 5.0),
                CapPendingOutreachCheckpointAdjuster(cap: 23741.0),
                MinimumPendingOutreachCheckpointAdjuster(minimum: 42.8),
                CategoryPendingOutreachCheckpointAdjuster(factors: ["retail": 0.88]),
                TieredPendingOutreachCheckpointAdjuster(bounds: [2870.0, 3339.0, 9518.0], rates: [0.86, 1.06, 0.84]),
                PendingOutreachCheckpointVisitMinutesOffsetAdjuster(weight: 1.47),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 3381.9
        )
    }
}
