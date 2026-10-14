import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial policy calculation.
    protocol DenialPolicyStep {
        func describe() -> String
        func adjust(_ item: DenialPolicy, value: Double) -> Double
    }

    final class RegionDenialPolicyAdjuster: DenialPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DenialPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDenialPolicyAdjuster: DenialPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDenialPolicyAdjuster: DenialPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialPolicyAdjuster: DenialPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial policy steps in order and keeps a trace of each.
    final class DenialPolicyEngine {
        var steps: [any DenialPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialPolicy) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [DenialPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialPolicyEngine() -> DenialPolicyEngine {
        return DenialPolicyEngine(
            steps: [
                RegionDenialPolicyAdjuster(factors: ["online": 1.24, "retail": 0.92]),
                CapDenialPolicyAdjuster(cap: 11284.0),
                PercentDenialPolicyAdjuster(percent: -12.7),
                MinimumDenialPolicyAdjuster(minimum: 24.8),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 72829.9
        )
    }
}
