import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient revocation group calculation.
    protocol LenientRevocationGroupModifier {
        func describe() -> String
        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double
    }

    final class LenientRevocationGroupExpiresAtOffsetAdjuster: LenientRevocationGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class FacilityLenientRevocationGroupAdjuster: LenientRevocationGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLenientRevocationGroupAdjuster: LenientRevocationGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientRevocationGroupAdjuster: LenientRevocationGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLenientRevocationGroupAdjuster: LenientRevocationGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientRevocationGroupAdjuster: LenientRevocationGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRevocationGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient revocation group steps in order and keeps a trace of each.
    final class LenientRevocationGroupEngine {
        var steps: [any LenientRevocationGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRevocationGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientRevocationGroup) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientRevocationGroupModifier = steps[index]
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

        func evaluateAll(_ items: [LenientRevocationGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientRevocationGroupEngine() -> LenientRevocationGroupEngine {
        return LenientRevocationGroupEngine(
            steps: [
                LenientRevocationGroupExpiresAtOffsetAdjuster(weight: 0.06),
                FacilityLenientRevocationGroupAdjuster(factors: ["central": 1.08]),
                PercentLenientRevocationGroupAdjuster(percent: -13.4),
                TieredLenientRevocationGroupAdjuster(
                    bounds: [1744.0, 3545.0, 4970.0, 9631.0],
                    rates: [0.95, 1.16, 1.17, 1.08]
                ),
                RoundingLenientRevocationGroupAdjuster(step: 5.0),
                MinimumLenientRevocationGroupAdjuster(minimum: 31.4),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 51360.8
        )
    }
}
