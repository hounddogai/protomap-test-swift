import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim profile calculation.
    protocol ClaimProfileStep {
        func describe() -> String
        func adjust(_ item: ClaimProfile, value: Double) -> Double
    }

    final class CapClaimProfileAdjuster: ClaimProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentClaimProfileAdjuster: ClaimProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ClaimProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumClaimProfileAdjuster: ClaimProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the claim profile steps in order and keeps a trace of each.
    final class ClaimProfileEngine {
        var steps: [any ClaimProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimProfile) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ClaimProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimProfileEngine() -> ClaimProfileEngine {
        return ClaimProfileEngine(
            steps: [
                CapClaimProfileAdjuster(cap: 8873.0),
                SegmentClaimProfileAdjuster(factors: ["east": 0.72]),
                MinimumClaimProfileAdjuster(minimum: 42.9),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 28998.2
        )
    }
}
