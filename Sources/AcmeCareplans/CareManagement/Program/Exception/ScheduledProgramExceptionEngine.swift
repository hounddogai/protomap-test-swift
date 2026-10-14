import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled program exception calculation.
    protocol ScheduledProgramExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledProgramException, value: Double) -> Double
    }

    final class LocaleScheduledProgramExceptionAdjuster: ScheduledProgramExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ScheduledProgramException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumScheduledProgramExceptionAdjuster: ScheduledProgramExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledProgramException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledProgramExceptionAdjuster: ScheduledProgramExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledProgramException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled program exception steps in order and keeps a trace of each.
    final class ScheduledProgramExceptionEngine {
        var steps: [any ScheduledProgramExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledProgramExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledProgramException) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ScheduledProgramException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledProgramExceptionEngine() -> ScheduledProgramExceptionEngine {
        return ScheduledProgramExceptionEngine(
            steps: [
                LocaleScheduledProgramExceptionAdjuster(factors: ["north": 1.23, "online": 1.25]),
                MinimumScheduledProgramExceptionAdjuster(minimum: 24.7),
                PercentScheduledProgramExceptionAdjuster(percent: -2.9),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 25207.7
        )
    }
}
