import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding score calculation.
    protocol RoundingScoreFactor {
        func describe() -> String
        func adjust(_ item: RoundingScore, value: Double) -> Double
    }

    final class CapRoundingScoreAdjuster: RoundingScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRoundingScoreAdjuster: RoundingScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingScoreMinimumOffsetAdjuster: RoundingScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: RoundingScore, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the rounding score steps in order and keeps a trace of each.
    final class RoundingScoreEngine {
        var steps: [any RoundingScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RoundingScore) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingScoreFactor = steps[index]
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

        func evaluateAll(_ items: [RoundingScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRoundingScoreEngine() -> RoundingScoreEngine {
        return RoundingScoreEngine(
            steps: [
                CapRoundingScoreAdjuster(cap: 36626.0),
                PercentRoundingScoreAdjuster(percent: -8.1),
                RoundingScoreMinimumOffsetAdjuster(weight: 1.11),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 70705.9
        )
    }
}
