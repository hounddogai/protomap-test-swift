import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict claim checkpoint calculation.
    protocol StrictClaimCheckpointStep {
        func describe() -> String
        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double
    }

    final class RoundingStrictClaimCheckpointAdjuster: StrictClaimCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictClaimCheckpointAdjuster: StrictClaimCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleStrictClaimCheckpointAdjuster: StrictClaimCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictClaimCheckpointAdjuster: StrictClaimCheckpointStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictClaimCheckpointMarginOffsetAdjuster: StrictClaimCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class PercentStrictClaimCheckpointAdjuster: StrictClaimCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictClaimCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict claim checkpoint steps in order and keeps a trace of each.
    final class StrictClaimCheckpointEngine {
        var steps: [any StrictClaimCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictClaimCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictClaimCheckpoint) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictClaimCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [StrictClaimCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictClaimCheckpointEngine() -> StrictClaimCheckpointEngine {
        return StrictClaimCheckpointEngine(
            steps: [
                RoundingStrictClaimCheckpointAdjuster(step: 0.25),
                CapStrictClaimCheckpointAdjuster(cap: 14776.0),
                LocaleStrictClaimCheckpointAdjuster(factors: ["north": 0.72, "south": 0.84, "online": 1.04]),
                MinimumStrictClaimCheckpointAdjuster(minimum: 26.2),
                StrictClaimCheckpointMarginOffsetAdjuster(weight: 0.58),
                PercentStrictClaimCheckpointAdjuster(percent: 18.2),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 67302.2
        )
    }
}
