import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped shift tier calculation.
    protocol CappedShiftTierFactor {
        func describe() -> String
        func adjust(_ item: CappedShiftTier, value: Double) -> Double
    }

    final class CapCappedShiftTierAdjuster: CappedShiftTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedShiftTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityCappedShiftTierAdjuster: CappedShiftTierFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CappedShiftTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedShiftTierAdjuster: CappedShiftTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedShiftTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped shift tier steps in order and keeps a trace of each.
    final class CappedShiftTierEngine {
        var steps: [any CappedShiftTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedShiftTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedShiftTier) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedShiftTierFactor = steps[index]
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

        func evaluateAll(_ items: [CappedShiftTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedShiftTierEngine() -> CappedShiftTierEngine {
        return CappedShiftTierEngine(
            steps: [
                CapCappedShiftTierAdjuster(cap: 20360.0),
                FacilityCappedShiftTierAdjuster(factors: ["north": 0.97, "central": 1.06, "retail": 1.2]),
                RoundingCappedShiftTierAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 95973.1
        )
    }
}
