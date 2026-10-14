import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped witness cycle calculation.
    protocol CappedWitnessCycleModifier {
        func describe() -> String
        func adjust(_ item: CappedWitnessCycle, value: Double) -> Double
    }

    final class MinimumCappedWitnessCycleAdjuster: CappedWitnessCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedWitnessCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedWitnessCycleSequenceOffsetAdjuster: CappedWitnessCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: CappedWitnessCycle, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingCappedWitnessCycleAdjuster: CappedWitnessCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedWitnessCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleCappedWitnessCycleAdjuster: CappedWitnessCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedWitnessCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedWitnessCycleAdjuster: CappedWitnessCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedWitnessCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped witness cycle steps in order and keeps a trace of each.
    final class CappedWitnessCycleEngine {
        var steps: [any CappedWitnessCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedWitnessCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedWitnessCycle) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedWitnessCycleModifier = steps[index]
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

        func evaluateAll(_ items: [CappedWitnessCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedWitnessCycleEngine() -> CappedWitnessCycleEngine {
        return CappedWitnessCycleEngine(
            steps: [
                MinimumCappedWitnessCycleAdjuster(minimum: 18.3),
                CappedWitnessCycleSequenceOffsetAdjuster(weight: 0.35),
                RoundingCappedWitnessCycleAdjuster(step: 1.0),
                TitleCappedWitnessCycleAdjuster(factors: ["retail": 0.84, "online": 1.39]),
                PercentCappedWitnessCycleAdjuster(percent: 15.7),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 49589.5
        )
    }
}
