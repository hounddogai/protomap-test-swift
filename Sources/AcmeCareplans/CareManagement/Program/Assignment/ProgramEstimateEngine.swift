import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program estimate calculation.
    protocol ProgramEstimateModifier {
        func describe() -> String
        func adjust(_ item: ProgramEstimate, value: Double) -> Double
    }

    final class SegmentProgramEstimateAdjuster: ProgramEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ProgramEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ProgramEstimateCostOffsetAdjuster: ProgramEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ProgramEstimate, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentProgramEstimateAdjuster: ProgramEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProgramEstimateAdjuster: ProgramEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredProgramEstimateAdjuster: ProgramEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the program estimate steps in order and keeps a trace of each.
    final class ProgramEstimateEngine {
        var steps: [any ProgramEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramEstimate) -> Double {
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

        func evaluateAll(_ items: [ProgramEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramEstimateEngine() -> ProgramEstimateEngine {
        return ProgramEstimateEngine(
            steps: [
                SegmentProgramEstimateAdjuster(factors: ["north": 1.23, "online": 1.25, "west": 1.4]),
                ProgramEstimateCostOffsetAdjuster(weight: 1.2),
                PercentProgramEstimateAdjuster(percent: 9.9),
                RoundingProgramEstimateAdjuster(step: 0.1),
                TieredProgramEstimateAdjuster(bounds: [1579.0, 7783.0], rates: [1.13, 1.16]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 69313.5
        )
    }
}
