import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default float pool claim calculation.
    protocol DefaultFloatPoolClaimStep {
        func describe() -> String
        func adjust(_ item: DefaultFloatPoolClaim, value: Double) -> Double
    }

    final class UnitDefaultFloatPoolClaimAdjuster: DefaultFloatPoolClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: DefaultFloatPoolClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultFloatPoolClaimAdjuster: DefaultFloatPoolClaimStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultFloatPoolClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultFloatPoolClaimAdjuster: DefaultFloatPoolClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultFloatPoolClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default float pool claim steps in order and keeps a trace of each.
    final class DefaultFloatPoolClaimEngine {
        var steps: [any DefaultFloatPoolClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultFloatPoolClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultFloatPoolClaim) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultFloatPoolClaimStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DefaultFloatPoolClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultFloatPoolClaimEngine() -> DefaultFloatPoolClaimEngine {
        return DefaultFloatPoolClaimEngine(
            steps: [
                UnitDefaultFloatPoolClaimAdjuster(factors: ["east": 1.25, "central": 1.0]),
                CapDefaultFloatPoolClaimAdjuster(cap: 11404.0),
                MinimumDefaultFloatPoolClaimAdjuster(minimum: 29.9),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 3897.9
        )
    }
}
