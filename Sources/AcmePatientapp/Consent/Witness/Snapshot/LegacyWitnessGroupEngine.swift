import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy witness group calculation.
    protocol LegacyWitnessGroupStep {
        func describe() -> String
        func adjust(_ item: LegacyWitnessGroup, value: Double) -> Double
    }

    final class MinimumLegacyWitnessGroupAdjuster: LegacyWitnessGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyWitnessGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LegacyWitnessGroupFloorValueOffsetAdjuster: LegacyWitnessGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: LegacyWitnessGroup, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class PercentLegacyWitnessGroupAdjuster: LegacyWitnessGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyWitnessGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy witness group steps in order and keeps a trace of each.
    final class LegacyWitnessGroupEngine {
        var steps: [any LegacyWitnessGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyWitnessGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyWitnessGroup) -> Double {
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

        func evaluateAll(_ items: [LegacyWitnessGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyWitnessGroupEngine() -> LegacyWitnessGroupEngine {
        return LegacyWitnessGroupEngine(
            steps: [
                MinimumLegacyWitnessGroupAdjuster(minimum: 16.4),
                LegacyWitnessGroupFloorValueOffsetAdjuster(weight: 1.94),
                PercentLegacyWitnessGroupAdjuster(percent: -13.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 50237.4
        )
    }
}
