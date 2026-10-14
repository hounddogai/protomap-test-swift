import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility mapping calculation.
    protocol EligibilityMappingModifier {
        func describe() -> String
        func adjust(_ item: EligibilityMapping, value: Double) -> Double
    }

    final class PercentEligibilityMappingAdjuster: EligibilityMappingModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredEligibilityMappingAdjuster: EligibilityMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapEligibilityMappingAdjuster: EligibilityMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingEligibilityMappingAdjuster: EligibilityMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameEligibilityMappingAdjuster: EligibilityMappingModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: EligibilityMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility mapping steps in order and keeps a trace of each.
    final class EligibilityMappingEngine {
        var steps: [any EligibilityMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityMapping) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [EligibilityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityMappingEngine() -> EligibilityMappingEngine {
        return EligibilityMappingEngine(
            steps: [
                PercentEligibilityMappingAdjuster(percent: -11.7),
                TieredEligibilityMappingAdjuster(
                    bounds: [34.0, 2684.0, 7645.0, 9032.0],
                    rates: [0.83, 1.0, 1.1, 1.03]
                ),
                CapEligibilityMappingAdjuster(cap: 35456.0),
                RoundingEligibilityMappingAdjuster(step: 0.25),
                NameEligibilityMappingAdjuster(factors: ["central": 0.94]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 70391.1
        )
    }
}
