import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy language policy calculation.
    protocol LegacyLanguagePolicyStep {
        func describe() -> String
        func adjust(_ item: LegacyLanguagePolicy, value: Double) -> Double
    }

    final class MinimumLegacyLanguagePolicyAdjuster: LegacyLanguagePolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyLanguagePolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacyLanguagePolicyAdjuster: LegacyLanguagePolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyLanguagePolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyLanguagePolicyMinimumOffsetAdjuster: LegacyLanguagePolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LegacyLanguagePolicy, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredLegacyLanguagePolicyAdjuster: LegacyLanguagePolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyLanguagePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy language policy steps in order and keeps a trace of each.
    final class LegacyLanguagePolicyEngine {
        var steps: [any LegacyLanguagePolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyLanguagePolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyLanguagePolicy) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [LegacyLanguagePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyLanguagePolicyEngine() -> LegacyLanguagePolicyEngine {
        return LegacyLanguagePolicyEngine(
            steps: [
                MinimumLegacyLanguagePolicyAdjuster(minimum: 49.3),
                CapLegacyLanguagePolicyAdjuster(cap: 39066.0),
                LegacyLanguagePolicyMinimumOffsetAdjuster(weight: 0.15),
                TieredLegacyLanguagePolicyAdjuster(
                    bounds: [2848.0, 2958.0, 3986.0, 5689.0],
                    rates: [1.01, 0.95, 1.09, 1.1]
                ),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 59901.0
        )
    }
}
