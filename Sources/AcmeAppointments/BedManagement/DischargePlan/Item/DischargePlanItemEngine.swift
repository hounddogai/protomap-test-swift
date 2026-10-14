import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan item calculation.
    protocol DischargePlanItemModifier {
        func describe() -> String
        func adjust(_ item: DischargePlanItem, value: Double) -> Double
    }

    final class WardDischargePlanItemAdjuster: DischargePlanItemModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DischargePlanItem, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDischargePlanItemAdjuster: DischargePlanItemModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanItem, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDischargePlanItemAdjuster: DischargePlanItemModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanItem, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the discharge plan item steps in order and keeps a trace of each.
    final class DischargePlanItemEngine {
        var steps: [any DischargePlanItemModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanItemModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DischargePlanItem) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [DischargePlanItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDischargePlanItemEngine() -> DischargePlanItemEngine {
        return DischargePlanItemEngine(
            steps: [
                WardDischargePlanItemAdjuster(factors: ["central": 0.76, "online": 0.8]),
                PercentDischargePlanItemAdjuster(percent: -3.9),
                CapDischargePlanItemAdjuster(cap: 44350.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 70850.6
        )
    }
}
