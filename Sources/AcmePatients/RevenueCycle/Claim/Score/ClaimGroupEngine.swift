import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim group calculation.
    protocol ClaimGroupAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimGroup, value: Double) -> Double
    }

    final class ClaimGroupPriorityOffsetAdjuster: ClaimGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ClaimGroup, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class NameClaimGroupAdjuster: ClaimGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClaimGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapClaimGroupAdjuster: ClaimGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the claim group steps in order and keeps a trace of each.
    final class ClaimGroupEngine {
        var steps: [any ClaimGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimGroup) -> Double {
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

        func evaluateAll(_ items: [ClaimGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimGroupEngine() -> ClaimGroupEngine {
        return ClaimGroupEngine(
            steps: [
                ClaimGroupPriorityOffsetAdjuster(weight: 0.18),
                NameClaimGroupAdjuster(factors: ["online": 1.37, "west": 1.05, "east": 1.16]),
                CapClaimGroupAdjuster(cap: 13120.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 71279.6
        )
    }
}
