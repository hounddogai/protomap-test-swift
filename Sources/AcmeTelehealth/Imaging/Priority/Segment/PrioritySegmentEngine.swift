import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority segment calculation.
    protocol PrioritySegmentStep {
        func describe() -> String
        func adjust(_ item: PrioritySegment, value: Double) -> Double
    }

    final class MinimumPrioritySegmentAdjuster: PrioritySegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrioritySegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentPrioritySegmentAdjuster: PrioritySegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PrioritySegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrioritySegmentAdjuster: PrioritySegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrioritySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrioritySegmentAdjuster: PrioritySegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrioritySegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrioritySegmentAdjuster: PrioritySegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrioritySegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrioritySegmentQuantityOffsetAdjuster: PrioritySegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PrioritySegment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the priority segment steps in order and keeps a trace of each.
    final class PrioritySegmentEngine {
        var steps: [any PrioritySegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrioritySegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrioritySegment) -> Double {
            var current = item.weightedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PrioritySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrioritySegmentEngine() -> PrioritySegmentEngine {
        return PrioritySegmentEngine(
            steps: [
                MinimumPrioritySegmentAdjuster(minimum: 3.4),
                SegmentPrioritySegmentAdjuster(factors: ["south": 0.95, "west": 1.15, "central": 0.98]),
                TieredPrioritySegmentAdjuster(bounds: [3290.0, 3580.0], rates: [0.82, 1.19]),
                RoundingPrioritySegmentAdjuster(step: 0.05),
                CapPrioritySegmentAdjuster(cap: 9986.0),
                PrioritySegmentQuantityOffsetAdjuster(weight: 0.73),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 53619.3
        )
    }
}
