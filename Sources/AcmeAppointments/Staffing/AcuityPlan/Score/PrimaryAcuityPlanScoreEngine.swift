import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary acuity plan score calculation.
    protocol PrimaryAcuityPlanScoreStep {
        func describe() -> String
        func adjust(_ item: PrimaryAcuityPlanScore, value: Double) -> Double
    }

    final class CapPrimaryAcuityPlanScoreAdjuster: PrimaryAcuityPlanScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryAcuityPlanScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryAcuityPlanScoreAdjuster: PrimaryAcuityPlanScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryAcuityPlanScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryAcuityPlanScoreAdjuster: PrimaryAcuityPlanScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryAcuityPlanScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary acuity plan score steps in order and keeps a trace of each.
    final class PrimaryAcuityPlanScoreEngine {
        var steps: [any PrimaryAcuityPlanScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAcuityPlanScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryAcuityPlanScore) -> Double {
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

        func evaluateAll(_ items: [PrimaryAcuityPlanScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryAcuityPlanScoreEngine() -> PrimaryAcuityPlanScoreEngine {
        return PrimaryAcuityPlanScoreEngine(
            steps: [
                CapPrimaryAcuityPlanScoreAdjuster(cap: 41259.0),
                PercentPrimaryAcuityPlanScoreAdjuster(percent: 9.6),
                RoundingPrimaryAcuityPlanScoreAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 37151.5
        )
    }
}
