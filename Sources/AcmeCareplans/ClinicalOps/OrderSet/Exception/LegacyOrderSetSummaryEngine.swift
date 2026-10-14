import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy order set summary calculation.
    protocol LegacyOrderSetSummaryModifier {
        func describe() -> String
        func adjust(_ item: LegacyOrderSetSummary, value: Double) -> Double
    }

    final class RoundingLegacyOrderSetSummaryAdjuster: LegacyOrderSetSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyOrderSetSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyOrderSetSummaryAdjuster: LegacyOrderSetSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyOrderSetSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyOrderSetSummaryDosageMgOffsetAdjuster: LegacyOrderSetSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: LegacyOrderSetSummary, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the legacy order set summary steps in order and keeps a trace of each.
    final class LegacyOrderSetSummaryEngine {
        var steps: [any LegacyOrderSetSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyOrderSetSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyOrderSetSummary) -> Double {
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

        func evaluateAll(_ items: [LegacyOrderSetSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyOrderSetSummaryEngine() -> LegacyOrderSetSummaryEngine {
        return LegacyOrderSetSummaryEngine(
            steps: [
                RoundingLegacyOrderSetSummaryAdjuster(step: 0.25),
                CapLegacyOrderSetSummaryAdjuster(cap: 40575.0),
                LegacyOrderSetSummaryDosageMgOffsetAdjuster(weight: 0.62),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 31396.1
        )
    }
}
