import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure claim calculation.
    protocol ClosureClaimFactor {
        func describe() -> String
        func adjust(_ item: ClosureClaim, value: Double) -> Double
    }

    final class CapClosureClaimAdjuster: ClosureClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingClosureClaimAdjuster: ClosureClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameClosureClaimAdjuster: ClosureClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClosureClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ClosureClaimRatioOffsetAdjuster: ClosureClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ClosureClaim, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the closure claim steps in order and keeps a trace of each.
    final class ClosureClaimEngine {
        var steps: [any ClosureClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureClaim) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureClaimFactor = steps[index]
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

        func evaluateAll(_ items: [ClosureClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureClaimEngine() -> ClosureClaimEngine {
        return ClosureClaimEngine(
            steps: [
                CapClosureClaimAdjuster(cap: 47266.0),
                RoundingClosureClaimAdjuster(step: 1.0),
                NameClosureClaimAdjuster(factors: ["retail": 1.12]),
                ClosureClaimRatioOffsetAdjuster(weight: 0.74),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 70992.6
        )
    }
}
