import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive care gap override calculation.
    protocol AdaptiveCareGapOverrideStep {
        func describe() -> String
        func adjust(_ item: AdaptiveCareGapOverride, value: Double) -> Double
    }

    final class CapAdaptiveCareGapOverrideAdjuster: AdaptiveCareGapOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveCareGapOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveCareGapOverrideVisitMinutesOffsetAdjuster: AdaptiveCareGapOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: AdaptiveCareGapOverride, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumAdaptiveCareGapOverrideAdjuster: AdaptiveCareGapOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCareGapOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelAdaptiveCareGapOverrideAdjuster: AdaptiveCareGapOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveCareGapOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveCareGapOverrideAdjuster: AdaptiveCareGapOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCareGapOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive care gap override steps in order and keeps a trace of each.
    final class AdaptiveCareGapOverrideEngine {
        var steps: [any AdaptiveCareGapOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCareGapOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveCareGapOverride) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [AdaptiveCareGapOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCareGapOverrideEngine() -> AdaptiveCareGapOverrideEngine {
        return AdaptiveCareGapOverrideEngine(
            steps: [
                CapAdaptiveCareGapOverrideAdjuster(cap: 30559.0),
                AdaptiveCareGapOverrideVisitMinutesOffsetAdjuster(weight: 1.95),
                MinimumAdaptiveCareGapOverrideAdjuster(minimum: 21.0),
                LabelAdaptiveCareGapOverrideAdjuster(factors: ["online": 0.75]),
                TieredAdaptiveCareGapOverrideAdjuster(bounds: [1769.0, 3074.0, 5318.0], rates: [1.12, 1.04, 0.82]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 78839.5
        )
    }
}
