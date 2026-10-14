import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict care protocol tier calculation.
    protocol StrictCareProtocolTierModifier {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double
    }

    final class StrictCareProtocolTierBatchSizeOffsetAdjuster: StrictCareProtocolTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class PercentStrictCareProtocolTierAdjuster: StrictCareProtocolTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictCareProtocolTierAdjuster: StrictCareProtocolTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityStrictCareProtocolTierAdjuster: StrictCareProtocolTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictCareProtocolTierAdjuster: StrictCareProtocolTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStrictCareProtocolTierAdjuster: StrictCareProtocolTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictCareProtocolTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict care protocol tier steps in order and keeps a trace of each.
    final class StrictCareProtocolTierEngine {
        var steps: [any StrictCareProtocolTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictCareProtocolTier) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [StrictCareProtocolTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolTierEngine() -> StrictCareProtocolTierEngine {
        return StrictCareProtocolTierEngine(
            steps: [
                StrictCareProtocolTierBatchSizeOffsetAdjuster(weight: 0.38),
                PercentStrictCareProtocolTierAdjuster(percent: -16.7),
                MinimumStrictCareProtocolTierAdjuster(minimum: 18.3),
                FacilityStrictCareProtocolTierAdjuster(factors: ["retail": 1.13, "north": 1.34]),
                CapStrictCareProtocolTierAdjuster(cap: 18970.0),
                TieredStrictCareProtocolTierAdjuster(bounds: [7179.0, 8724.0], rates: [1.11, 0.95]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 53963.1
        )
    }
}
