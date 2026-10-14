import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient care protocol segment calculation.
    protocol LenientCareProtocolSegmentModifier {
        func describe() -> String
        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double
    }

    final class TieredLenientCareProtocolSegmentAdjuster: LenientCareProtocolSegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleLenientCareProtocolSegmentAdjuster: LenientCareProtocolSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientCareProtocolSegmentAdjuster: LenientCareProtocolSegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientCareProtocolSegmentAdjuster: LenientCareProtocolSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientCareProtocolSegmentAdjuster: LenientCareProtocolSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientCareProtocolSegmentAdjuster: LenientCareProtocolSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareProtocolSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient care protocol segment steps in order and keeps a trace of each.
    final class LenientCareProtocolSegmentEngine {
        var steps: [any LenientCareProtocolSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareProtocolSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientCareProtocolSegment) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCareProtocolSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [LenientCareProtocolSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientCareProtocolSegmentEngine() -> LenientCareProtocolSegmentEngine {
        return LenientCareProtocolSegmentEngine(
            steps: [
                TieredLenientCareProtocolSegmentAdjuster(bounds: [942.0, 6852.0], rates: [1.17, 1.14]),
                LocaleLenientCareProtocolSegmentAdjuster(factors: ["north": 1.1]),
                CapLenientCareProtocolSegmentAdjuster(cap: 39989.0),
                PercentLenientCareProtocolSegmentAdjuster(percent: 6.8),
                RoundingLenientCareProtocolSegmentAdjuster(step: 0.1),
                MinimumLenientCareProtocolSegmentAdjuster(minimum: 2.8),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 94746.3
        )
    }
}
