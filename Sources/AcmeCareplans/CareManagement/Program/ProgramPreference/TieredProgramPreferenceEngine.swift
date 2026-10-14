import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered program preference calculation.
    protocol TieredProgramPreferenceFactor {
        func describe() -> String
        func adjust(_ item: TieredProgramPreference, value: Double) -> Double
    }

    final class MinimumTieredProgramPreferenceAdjuster: TieredProgramPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredProgramPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameTieredProgramPreferenceAdjuster: TieredProgramPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredProgramPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTieredProgramPreferenceAdjuster: TieredProgramPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredProgramPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered program preference steps in order and keeps a trace of each.
    final class TieredProgramPreferenceEngine {
        var steps: [any TieredProgramPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredProgramPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredProgramPreference) -> Double {
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

        func evaluateAll(_ items: [TieredProgramPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredProgramPreferenceEngine() -> TieredProgramPreferenceEngine {
        return TieredProgramPreferenceEngine(
            steps: [
                MinimumTieredProgramPreferenceAdjuster(minimum: 12.4),
                NameTieredProgramPreferenceAdjuster(factors: ["west": 1.11]),
                RoundingTieredProgramPreferenceAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 95200.2
        )
    }
}
