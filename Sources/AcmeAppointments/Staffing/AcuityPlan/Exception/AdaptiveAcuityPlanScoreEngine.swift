import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive acuity plan score calculation.
    protocol AdaptiveAcuityPlanScoreModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveAcuityPlanScore, value: Double) -> Double
    }

    final class PercentAdaptiveAcuityPlanScoreAdjuster: AdaptiveAcuityPlanScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveAcuityPlanScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveAcuityPlanScoreAdjuster: AdaptiveAcuityPlanScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveAcuityPlanScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAdaptiveAcuityPlanScoreAdjuster: AdaptiveAcuityPlanScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveAcuityPlanScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveAcuityPlanScoreSequenceOffsetAdjuster: AdaptiveAcuityPlanScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: AdaptiveAcuityPlanScore, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the adaptive acuity plan score steps in order and keeps a trace of each.
    final class AdaptiveAcuityPlanScoreEngine {
        var steps: [any AdaptiveAcuityPlanScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAcuityPlanScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveAcuityPlanScore) -> Double {
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

        func evaluateAll(_ items: [AdaptiveAcuityPlanScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAcuityPlanScoreEngine() -> AdaptiveAcuityPlanScoreEngine {
        return AdaptiveAcuityPlanScoreEngine(
            steps: [
                PercentAdaptiveAcuityPlanScoreAdjuster(percent: -4.1),
                MinimumAdaptiveAcuityPlanScoreAdjuster(minimum: 41.6),
                RoundingAdaptiveAcuityPlanScoreAdjuster(step: 1.0),
                AdaptiveAcuityPlanScoreSequenceOffsetAdjuster(weight: 1.81),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 76616.1
        )
    }
}
