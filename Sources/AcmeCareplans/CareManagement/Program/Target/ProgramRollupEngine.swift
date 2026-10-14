import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program rollup calculation.
    protocol ProgramRollupStep {
        func describe() -> String
        func adjust(_ item: ProgramRollup, value: Double) -> Double
    }

    final class TieredProgramRollupAdjuster: ProgramRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ProgramRollupRatioOffsetAdjuster: ProgramRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ProgramRollup, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingProgramRollupAdjuster: ProgramRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the program rollup steps in order and keeps a trace of each.
    final class ProgramRollupEngine {
        var steps: [any ProgramRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProgramRollup) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [ProgramRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProgramRollupEngine() -> ProgramRollupEngine {
        return ProgramRollupEngine(
            steps: [
                TieredProgramRollupAdjuster(bounds: [5724.0, 6678.0, 7663.0, 9520.0], rates: [1.18, 0.83, 0.81, 1.13]),
                ProgramRollupRatioOffsetAdjuster(weight: 0.68),
                RoundingProgramRollupAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 66848.4
        )
    }
}
