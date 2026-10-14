import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual acuity plan draft calculation.
    protocol ManualAcuityPlanDraftStep {
        func describe() -> String
        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double
    }

    final class PercentManualAcuityPlanDraftAdjuster: ManualAcuityPlanDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualAcuityPlanDraftAdjuster: ManualAcuityPlanDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualAcuityPlanDraftAdjuster: ManualAcuityPlanDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualAcuityPlanDraftAdjuster: ManualAcuityPlanDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualAcuityPlanDraftAdjuster: ManualAcuityPlanDraftStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameManualAcuityPlanDraftAdjuster: ManualAcuityPlanDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualAcuityPlanDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual acuity plan draft steps in order and keeps a trace of each.
    final class ManualAcuityPlanDraftEngine {
        var steps: [any ManualAcuityPlanDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAcuityPlanDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualAcuityPlanDraft) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [ManualAcuityPlanDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualAcuityPlanDraftEngine() -> ManualAcuityPlanDraftEngine {
        return ManualAcuityPlanDraftEngine(
            steps: [
                PercentManualAcuityPlanDraftAdjuster(percent: -17.8),
                RoundingManualAcuityPlanDraftAdjuster(step: 0.05),
                MinimumManualAcuityPlanDraftAdjuster(minimum: 22.4),
                TieredManualAcuityPlanDraftAdjuster(bounds: [331.0, 8824.0], rates: [0.83, 0.88]),
                CapManualAcuityPlanDraftAdjuster(cap: 16552.0),
                NameManualAcuityPlanDraftAdjuster(factors: ["north": 1.31]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 44312.1
        )
    }
}
