import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict interaction audit calculation.
    protocol StrictInteractionAuditFactor {
        func describe() -> String
        func adjust(_ item: StrictInteractionAudit, value: Double) -> Double
    }

    final class LabelStrictInteractionAuditAdjuster: StrictInteractionAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictInteractionAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictInteractionAuditAdjuster: StrictInteractionAuditFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictInteractionAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictInteractionAuditBudgetOffsetAdjuster: StrictInteractionAuditFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: StrictInteractionAudit, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapStrictInteractionAuditAdjuster: StrictInteractionAuditFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictInteractionAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingStrictInteractionAuditAdjuster: StrictInteractionAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictInteractionAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict interaction audit steps in order and keeps a trace of each.
    final class StrictInteractionAuditEngine {
        var steps: [any StrictInteractionAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictInteractionAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictInteractionAudit) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [StrictInteractionAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictInteractionAuditEngine() -> StrictInteractionAuditEngine {
        return StrictInteractionAuditEngine(
            steps: [
                LabelStrictInteractionAuditAdjuster(factors: ["east": 0.91, "online": 0.95, "south": 1.34]),
                MinimumStrictInteractionAuditAdjuster(minimum: 42.6),
                StrictInteractionAuditBudgetOffsetAdjuster(weight: 0.65),
                CapStrictInteractionAuditAdjuster(cap: 22713.0),
                RoundingStrictInteractionAuditAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 37363.9
        )
    }
}
