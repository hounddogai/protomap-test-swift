import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality tier calculation.
    protocol ModalityTierStep {
        func describe() -> String
        func adjust(_ item: ModalityTier, value: Double) -> Double
    }

    final class PercentModalityTierAdjuster: ModalityTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardModalityTierAdjuster: ModalityTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ModalityTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumModalityTierAdjuster: ModalityTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the modality tier steps in order and keeps a trace of each.
    final class ModalityTierEngine {
        var steps: [any ModalityTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalityTier) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityTierStep = steps[index]
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

        func evaluateAll(_ items: [ModalityTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalityTierEngine() -> ModalityTierEngine {
        return ModalityTierEngine(
            steps: [
                PercentModalityTierAdjuster(percent: -15.3),
                WardModalityTierAdjuster(factors: ["south": 0.95, "east": 1.27, "central": 0.97]),
                MinimumModalityTierAdjuster(minimum: 21.8),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 30252.2
        )
    }
}
