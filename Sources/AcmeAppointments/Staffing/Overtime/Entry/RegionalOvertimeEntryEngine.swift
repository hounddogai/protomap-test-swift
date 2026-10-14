import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional overtime entry calculation.
    protocol RegionalOvertimeEntryStep {
        func describe() -> String
        func adjust(_ item: RegionalOvertimeEntry, value: Double) -> Double
    }

    final class RegionRegionalOvertimeEntryAdjuster: RegionalOvertimeEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalOvertimeEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalOvertimeEntryAdjuster: RegionalOvertimeEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalOvertimeEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalOvertimeEntryWindowDaysOffsetAdjuster: RegionalOvertimeEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: RegionalOvertimeEntry, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class PercentRegionalOvertimeEntryAdjuster: RegionalOvertimeEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOvertimeEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional overtime entry steps in order and keeps a trace of each.
    final class RegionalOvertimeEntryEngine {
        var steps: [any RegionalOvertimeEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOvertimeEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalOvertimeEntry) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalOvertimeEntryStep = steps[index]
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

        func evaluateAll(_ items: [RegionalOvertimeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalOvertimeEntryEngine() -> RegionalOvertimeEntryEngine {
        return RegionalOvertimeEntryEngine(
            steps: [
                RegionRegionalOvertimeEntryAdjuster(factors: ["retail": 0.92, "west": 0.78]),
                RoundingRegionalOvertimeEntryAdjuster(step: 0.05),
                RegionalOvertimeEntryWindowDaysOffsetAdjuster(weight: 0.18),
                PercentRegionalOvertimeEntryAdjuster(percent: -2.7),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 43654.2
        )
    }
}
