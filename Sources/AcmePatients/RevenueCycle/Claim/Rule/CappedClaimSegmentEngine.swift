import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped claim segment calculation.
    protocol CappedClaimSegmentModifier {
        func describe() -> String
        func adjust(_ item: CappedClaimSegment, value: Double) -> Double
    }

    final class MinimumCappedClaimSegmentAdjuster: CappedClaimSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedClaimSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCappedClaimSegmentAdjuster: CappedClaimSegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedClaimSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedClaimSegmentRatioOffsetAdjuster: CappedClaimSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: CappedClaimSegment, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TitleCappedClaimSegmentAdjuster: CappedClaimSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedClaimSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedClaimSegmentAdjuster: CappedClaimSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedClaimSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped claim segment steps in order and keeps a trace of each.
    final class CappedClaimSegmentEngine {
        var steps: [any CappedClaimSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedClaimSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedClaimSegment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedClaimSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [CappedClaimSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedClaimSegmentEngine() -> CappedClaimSegmentEngine {
        return CappedClaimSegmentEngine(
            steps: [
                MinimumCappedClaimSegmentAdjuster(minimum: 26.5),
                TieredCappedClaimSegmentAdjuster(bounds: [3660.0, 7552.0], rates: [0.91, 1.05]),
                CappedClaimSegmentRatioOffsetAdjuster(weight: 1.01),
                TitleCappedClaimSegmentAdjuster(factors: ["central": 0.97]),
                PercentCappedClaimSegmentAdjuster(percent: 3.2),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 37488.9
        )
    }
}
