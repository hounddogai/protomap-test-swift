import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation claim calculation.
    protocol IsolationClaimModifier {
        func describe() -> String
        func adjust(_ item: IsolationClaim, value: Double) -> Double
    }

    final class TieredIsolationClaimAdjuster: IsolationClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumIsolationClaimAdjuster: IsolationClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapIsolationClaimAdjuster: IsolationClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryIsolationClaimAdjuster: IsolationClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: IsolationClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingIsolationClaimAdjuster: IsolationClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the isolation claim steps in order and keeps a trace of each.
    final class IsolationClaimEngine {
        var steps: [any IsolationClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationClaim) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [IsolationClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationClaimEngine() -> IsolationClaimEngine {
        return IsolationClaimEngine(
            steps: [
                TieredIsolationClaimAdjuster(bounds: [813.0, 4439.0], rates: [0.95, 1.07]),
                MinimumIsolationClaimAdjuster(minimum: 28.3),
                CapIsolationClaimAdjuster(cap: 37612.0),
                CategoryIsolationClaimAdjuster(factors: ["east": 0.88]),
                RoundingIsolationClaimAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 95577.7
        )
    }
}
