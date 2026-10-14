import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient specimen policy calculation.
    protocol LenientSpecimenPolicyStep {
        func describe() -> String
        func adjust(_ item: LenientSpecimenPolicy, value: Double) -> Double
    }

    final class RoundingLenientSpecimenPolicyAdjuster: LenientSpecimenPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSpecimenPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientSpecimenPolicyAdjuster: LenientSpecimenPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSpecimenPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientSpecimenPolicyAdjuster: LenientSpecimenPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientSpecimenPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientSpecimenPolicyAdjuster: LenientSpecimenPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientSpecimenPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient specimen policy steps in order and keeps a trace of each.
    final class LenientSpecimenPolicyEngine {
        var steps: [any LenientSpecimenPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSpecimenPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientSpecimenPolicy) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [LenientSpecimenPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientSpecimenPolicyEngine() -> LenientSpecimenPolicyEngine {
        return LenientSpecimenPolicyEngine(
            steps: [
                RoundingLenientSpecimenPolicyAdjuster(step: 0.1),
                TieredLenientSpecimenPolicyAdjuster(bounds: [5407.0, 6273.0], rates: [0.83, 0.99]),
                CapLenientSpecimenPolicyAdjuster(cap: 47432.0),
                MinimumLenientSpecimenPolicyAdjuster(minimum: 40.3),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 29495.2
        )
    }
}
