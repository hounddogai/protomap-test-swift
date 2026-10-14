import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped statement claim calculation.
    protocol CappedStatementClaimFactor {
        func describe() -> String
        func adjust(_ item: CappedStatementClaim, value: Double) -> Double
    }

    final class CappedStatementClaimAmountOffsetAdjuster: CappedStatementClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CappedStatementClaim, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapCappedStatementClaimAdjuster: CappedStatementClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedStatementClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitCappedStatementClaimAdjuster: CappedStatementClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedStatementClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedStatementClaimAdjuster: CappedStatementClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedStatementClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedStatementClaimAdjuster: CappedStatementClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedStatementClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped statement claim steps in order and keeps a trace of each.
    final class CappedStatementClaimEngine {
        var steps: [any CappedStatementClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedStatementClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedStatementClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedStatementClaimFactor = steps[index]
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

        func evaluateAll(_ items: [CappedStatementClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedStatementClaimEngine() -> CappedStatementClaimEngine {
        return CappedStatementClaimEngine(
            steps: [
                CappedStatementClaimAmountOffsetAdjuster(weight: 0.44),
                CapCappedStatementClaimAdjuster(cap: 8754.0),
                UnitCappedStatementClaimAdjuster(factors: ["central": 0.84, "online": 1.11]),
                RoundingCappedStatementClaimAdjuster(step: 5.0),
                PercentCappedStatementClaimAdjuster(percent: 6.7),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 29875.5
        )
    }
}
