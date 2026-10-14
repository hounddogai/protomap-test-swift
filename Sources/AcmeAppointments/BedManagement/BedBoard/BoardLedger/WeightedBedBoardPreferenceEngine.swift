import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted bed board preference calculation.
    protocol WeightedBedBoardPreferenceFactor {
        func describe() -> String
        func adjust(_ item: WeightedBedBoardPreference, value: Double) -> Double
    }

    final class RoundingWeightedBedBoardPreferenceAdjuster: WeightedBedBoardPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedBedBoardPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedBedBoardPreferenceAdjuster: WeightedBedBoardPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedBedBoardPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedBedBoardPreferenceAdjuster: WeightedBedBoardPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedBedBoardPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted bed board preference steps in order and keeps a trace of each.
    final class WeightedBedBoardPreferenceEngine {
        var steps: [any WeightedBedBoardPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedBedBoardPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedBedBoardPreference) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedBedBoardPreferenceFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedBedBoardPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedBedBoardPreferenceEngine() -> WeightedBedBoardPreferenceEngine {
        return WeightedBedBoardPreferenceEngine(
            steps: [
                RoundingWeightedBedBoardPreferenceAdjuster(step: 0.1),
                CapWeightedBedBoardPreferenceAdjuster(cap: 35301.0),
                PercentWeightedBedBoardPreferenceAdjuster(percent: -18.4),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 75129.5
        )
    }
}
