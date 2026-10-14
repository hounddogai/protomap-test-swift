import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global program preference calculation.
    protocol GlobalProgramPreferenceStep {
        func describe() -> String
        func adjust(_ item: GlobalProgramPreference, value: Double) -> Double
    }

    final class RoundingGlobalProgramPreferenceAdjuster: GlobalProgramPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalProgramPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalProgramPreferenceAdjuster: GlobalProgramPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalProgramPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalProgramPreferenceAdjuster: GlobalProgramPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalProgramPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalProgramPreferenceMinimumOffsetAdjuster: GlobalProgramPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: GlobalProgramPreference, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the global program preference steps in order and keeps a trace of each.
    final class GlobalProgramPreferenceEngine {
        var steps: [any GlobalProgramPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalProgramPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalProgramPreference) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalProgramPreferenceStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalProgramPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalProgramPreferenceEngine() -> GlobalProgramPreferenceEngine {
        return GlobalProgramPreferenceEngine(
            steps: [
                RoundingGlobalProgramPreferenceAdjuster(step: 0.1),
                PercentGlobalProgramPreferenceAdjuster(percent: -17.3),
                TieredGlobalProgramPreferenceAdjuster(
                    bounds: [6624.0, 8298.0, 8538.0, 9227.0],
                    rates: [0.95, 1.03, 1.1, 0.9]
                ),
                GlobalProgramPreferenceMinimumOffsetAdjuster(weight: 1.73),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 81984.1
        )
    }
}
