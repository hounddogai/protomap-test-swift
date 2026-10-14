import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation schedule calculation.
    protocol IsolationScheduleStep {
        func describe() -> String
        func adjust(_ item: IsolationSchedule, value: Double) -> Double
    }

    final class TitleIsolationScheduleAdjuster: IsolationScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: IsolationSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingIsolationScheduleAdjuster: IsolationScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class IsolationScheduleCapacityOffsetAdjuster: IsolationScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: IsolationSchedule, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredIsolationScheduleAdjuster: IsolationScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the isolation schedule steps in order and keeps a trace of each.
    final class IsolationScheduleEngine {
        var steps: [any IsolationScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationSchedule) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [IsolationSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationScheduleEngine() -> IsolationScheduleEngine {
        return IsolationScheduleEngine(
            steps: [
                TitleIsolationScheduleAdjuster(factors: ["central": 0.74, "retail": 0.73]),
                RoundingIsolationScheduleAdjuster(step: 5.0),
                IsolationScheduleCapacityOffsetAdjuster(weight: 1.23),
                TieredIsolationScheduleAdjuster(
                    bounds: [655.0, 1002.0, 2660.0, 4416.0],
                    rates: [1.06, 0.86, 0.94, 0.84]
                ),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 17267.6
        )
    }
}
