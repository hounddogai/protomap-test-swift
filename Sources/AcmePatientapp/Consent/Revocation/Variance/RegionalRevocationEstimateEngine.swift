import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional revocation estimate calculation.
    protocol RegionalRevocationEstimateModifier {
        func describe() -> String
        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double
    }

    final class TieredRegionalRevocationEstimateAdjuster: RegionalRevocationEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionRegionalRevocationEstimateAdjuster: RegionalRevocationEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalRevocationEstimateAdjuster: RegionalRevocationEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalRevocationEstimateAdjuster: RegionalRevocationEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRegionalRevocationEstimateAdjuster: RegionalRevocationEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalRevocationEstimateAcuityOffsetAdjuster: RegionalRevocationEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RegionalRevocationEstimate, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the regional revocation estimate steps in order and keeps a trace of each.
    final class RegionalRevocationEstimateEngine {
        var steps: [any RegionalRevocationEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRevocationEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalRevocationEstimate) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [RegionalRevocationEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalRevocationEstimateEngine() -> RegionalRevocationEstimateEngine {
        return RegionalRevocationEstimateEngine(
            steps: [
                TieredRegionalRevocationEstimateAdjuster(bounds: [1569.0, 8726.0], rates: [1.03, 1.07]),
                RegionRegionalRevocationEstimateAdjuster(factors: ["retail": 1.29, "west": 0.72, "online": 0.75]),
                PercentRegionalRevocationEstimateAdjuster(percent: -0.8),
                MinimumRegionalRevocationEstimateAdjuster(minimum: 3.5),
                CapRegionalRevocationEstimateAdjuster(cap: 38128.0),
                RegionalRevocationEstimateAcuityOffsetAdjuster(weight: 1.19),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 30186.3
        )
    }
}
