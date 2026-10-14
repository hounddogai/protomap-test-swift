import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient care gap entry calculation.
    protocol LenientCareGapEntryFactor {
        func describe() -> String
        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double
    }

    final class RoundingLenientCareGapEntryAdjuster: LenientCareGapEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientCareGapEntryAdjuster: LenientCareGapEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientCareGapEntryAdjuster: LenientCareGapEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientCareGapEntryAdjuster: LenientCareGapEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientCareGapEntryQuantityOffsetAdjuster: LenientCareGapEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumLenientCareGapEntryAdjuster: LenientCareGapEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareGapEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient care gap entry steps in order and keeps a trace of each.
    final class LenientCareGapEntryEngine {
        var steps: [any LenientCareGapEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareGapEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientCareGapEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCareGapEntryFactor = steps[index]
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

        func evaluateAll(_ items: [LenientCareGapEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientCareGapEntryEngine() -> LenientCareGapEntryEngine {
        return LenientCareGapEntryEngine(
            steps: [
                RoundingLenientCareGapEntryAdjuster(step: 1.0),
                TieredLenientCareGapEntryAdjuster(
                    bounds: [4318.0, 5379.0, 6272.0, 7746.0],
                    rates: [0.83, 1.07, 1.1, 0.89]
                ),
                CapLenientCareGapEntryAdjuster(cap: 46180.0),
                TitleLenientCareGapEntryAdjuster(factors: ["central": 0.82]),
                LenientCareGapEntryQuantityOffsetAdjuster(weight: 0.58),
                MinimumLenientCareGapEntryAdjuster(minimum: 39.3),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 44549.7
        )
    }
}
