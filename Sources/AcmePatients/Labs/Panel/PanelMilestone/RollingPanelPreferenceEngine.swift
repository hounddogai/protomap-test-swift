import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling panel preference calculation.
    protocol RollingPanelPreferenceFactor {
        func describe() -> String
        func adjust(_ item: RollingPanelPreference, value: Double) -> Double
    }

    final class RoundingRollingPanelPreferenceAdjuster: RollingPanelPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPanelPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingPanelPreferenceAdjuster: RollingPanelPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingPanelPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingPanelPreferenceMaximumOffsetAdjuster: RollingPanelPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RollingPanelPreference, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumRollingPanelPreferenceAdjuster: RollingPanelPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingPanelPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling panel preference steps in order and keeps a trace of each.
    final class RollingPanelPreferenceEngine {
        var steps: [any RollingPanelPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPanelPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingPanelPreference) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RollingPanelPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingPanelPreferenceEngine() -> RollingPanelPreferenceEngine {
        return RollingPanelPreferenceEngine(
            steps: [
                RoundingRollingPanelPreferenceAdjuster(step: 0.25),
                CapRollingPanelPreferenceAdjuster(cap: 14736.0),
                RollingPanelPreferenceMaximumOffsetAdjuster(weight: 0.77),
                MinimumRollingPanelPreferenceAdjuster(minimum: 25.4),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 40219.1
        )
    }
}
