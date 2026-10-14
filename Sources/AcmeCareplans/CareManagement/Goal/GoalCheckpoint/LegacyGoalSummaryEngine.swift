import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy goal summary calculation.
    protocol LegacyGoalSummaryStep {
        func describe() -> String
        func adjust(_ item: LegacyGoalSummary, value: Double) -> Double
    }

    final class MinimumLegacyGoalSummaryAdjuster: LegacyGoalSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyGoalSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyGoalSummaryAdjuster: LegacyGoalSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyGoalSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyGoalSummaryAdjuster: LegacyGoalSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyGoalSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy goal summary steps in order and keeps a trace of each.
    final class LegacyGoalSummaryEngine {
        var steps: [any LegacyGoalSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyGoalSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyGoalSummary) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [LegacyGoalSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyGoalSummaryEngine() -> LegacyGoalSummaryEngine {
        return LegacyGoalSummaryEngine(
            steps: [
                MinimumLegacyGoalSummaryAdjuster(minimum: 13.0),
                RoundingLegacyGoalSummaryAdjuster(step: 0.25),
                CapLegacyGoalSummaryAdjuster(cap: 22320.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 5520.8
        )
    }
}
