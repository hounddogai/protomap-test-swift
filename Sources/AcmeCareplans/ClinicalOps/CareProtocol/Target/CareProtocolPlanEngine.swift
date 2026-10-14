import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol plan calculation.
    protocol CareProtocolPlanModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolPlan, value: Double) -> Double
    }

    final class CapCareProtocolPlanAdjuster: CareProtocolPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameCareProtocolPlanAdjuster: CareProtocolPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareProtocolPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareProtocolPlanAdjuster: CareProtocolPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care protocol plan steps in order and keeps a trace of each.
    final class CareProtocolPlanEngine {
        var steps: [any CareProtocolPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolPlan) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CareProtocolPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolPlanEngine() -> CareProtocolPlanEngine {
        return CareProtocolPlanEngine(
            steps: [
                CapCareProtocolPlanAdjuster(cap: 16486.0),
                NameCareProtocolPlanAdjuster(factors: ["south": 0.88, "west": 1.4, "north": 1.07]),
                RoundingCareProtocolPlanAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 77608.7
        )
    }
}
