import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped follow up checkpoint calculation.
    protocol CappedFollowUpCheckpointModifier {
        func describe() -> String
        func adjust(_ item: CappedFollowUpCheckpoint, value: Double) -> Double
    }

    final class RoundingCappedFollowUpCheckpointAdjuster: CappedFollowUpCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedFollowUpCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedFollowUpCheckpointAdjuster: CappedFollowUpCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedFollowUpCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedFollowUpCheckpointScoreOffsetAdjuster: CappedFollowUpCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: CappedFollowUpCheckpoint, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredCappedFollowUpCheckpointAdjuster: CappedFollowUpCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedFollowUpCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped follow up checkpoint steps in order and keeps a trace of each.
    final class CappedFollowUpCheckpointEngine {
        var steps: [any CappedFollowUpCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedFollowUpCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedFollowUpCheckpoint) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedFollowUpCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [CappedFollowUpCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedFollowUpCheckpointEngine() -> CappedFollowUpCheckpointEngine {
        return CappedFollowUpCheckpointEngine(
            steps: [
                RoundingCappedFollowUpCheckpointAdjuster(step: 1.0),
                PercentCappedFollowUpCheckpointAdjuster(percent: -9.0),
                CappedFollowUpCheckpointScoreOffsetAdjuster(weight: 1.1),
                TieredCappedFollowUpCheckpointAdjuster(bounds: [462.0, 4395.0, 8784.0], rates: [0.82, 1.2, 1.14]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 20965.9
        )
    }
}
