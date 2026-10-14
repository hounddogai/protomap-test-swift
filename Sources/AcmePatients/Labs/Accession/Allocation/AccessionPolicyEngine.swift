import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession policy calculation.
    protocol AccessionPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionPolicy, value: Double) -> Double
    }

    final class CapAccessionPolicyAdjuster: AccessionPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AccessionPolicyMinimumOffsetAdjuster: AccessionPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: AccessionPolicy, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingAccessionPolicyAdjuster: AccessionPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleAccessionPolicyAdjuster: AccessionPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AccessionPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAccessionPolicyAdjuster: AccessionPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the accession policy steps in order and keeps a trace of each.
    final class AccessionPolicyEngine {
        var steps: [any AccessionPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionPolicy) -> Double {
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

        func evaluateAll(_ items: [AccessionPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionPolicyEngine() -> AccessionPolicyEngine {
        return AccessionPolicyEngine(
            steps: [
                CapAccessionPolicyAdjuster(cap: 35321.0),
                AccessionPolicyMinimumOffsetAdjuster(weight: 0.96),
                RoundingAccessionPolicyAdjuster(step: 0.25),
                TitleAccessionPolicyAdjuster(factors: ["west": 1.32, "east": 1.36, "south": 1.18]),
                TieredAccessionPolicyAdjuster(bounds: [4650.0, 9943.0], rates: [1.17, 1.18]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 89151.0
        )
    }
}
