import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding variance calculation.
    protocol RoundingVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingVariance, value: Double) -> Double
    }

    final class RoundingVarianceRateOffsetAdjuster: RoundingVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RoundingVariance, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapRoundingVarianceAdjuster: RoundingVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRoundingVarianceAdjuster: RoundingVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rounding variance steps in order and keeps a trace of each.
    final class RoundingVarianceEngine {
        var steps: [any RoundingVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingVariance) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [RoundingVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingVarianceEngine() -> RoundingVarianceEngine {
        return RoundingVarianceEngine(
            steps: [
                RoundingVarianceRateOffsetAdjuster(weight: 1.54),
                CapRoundingVarianceAdjuster(cap: 38846.0),
                PercentRoundingVarianceAdjuster(percent: 20.9),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 55906.1
        )
    }
}
