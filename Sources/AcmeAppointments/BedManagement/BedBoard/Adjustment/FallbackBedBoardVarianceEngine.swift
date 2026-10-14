import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback bed board variance calculation.
    protocol FallbackBedBoardVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double
    }

    final class CapFallbackBedBoardVarianceAdjuster: FallbackBedBoardVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackBedBoardVarianceAdjuster: FallbackBedBoardVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackBedBoardVarianceAmountOffsetAdjuster: FallbackBedBoardVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class SegmentFallbackBedBoardVarianceAdjuster: FallbackBedBoardVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackBedBoardVarianceAdjuster: FallbackBedBoardVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackBedBoardVarianceAdjuster: FallbackBedBoardVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackBedBoardVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback bed board variance steps in order and keeps a trace of each.
    final class FallbackBedBoardVarianceEngine {
        var steps: [any FallbackBedBoardVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackBedBoardVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackBedBoardVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackBedBoardVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackBedBoardVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackBedBoardVarianceEngine() -> FallbackBedBoardVarianceEngine {
        return FallbackBedBoardVarianceEngine(
            steps: [
                CapFallbackBedBoardVarianceAdjuster(cap: 1882.0),
                PercentFallbackBedBoardVarianceAdjuster(percent: 7.1),
                FallbackBedBoardVarianceAmountOffsetAdjuster(weight: 0.79),
                SegmentFallbackBedBoardVarianceAdjuster(factors: ["south": 0.83, "east": 1.32, "west": 1.36]),
                MinimumFallbackBedBoardVarianceAdjuster(minimum: 17.0),
                RoundingFallbackBedBoardVarianceAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 22455.9
        )
    }
}
