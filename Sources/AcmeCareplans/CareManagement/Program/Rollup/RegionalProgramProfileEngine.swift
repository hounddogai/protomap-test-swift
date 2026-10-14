import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional program profile calculation.
    protocol RegionalProgramProfileStep {
        func describe() -> String
        func adjust(_ item: RegionalProgramProfile, value: Double) -> Double
    }

    final class PercentRegionalProgramProfileAdjuster: RegionalProgramProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalProgramProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalProgramProfileAdjuster: RegionalProgramProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalProgramProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryRegionalProgramProfileAdjuster: RegionalProgramProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RegionalProgramProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional program profile steps in order and keeps a trace of each.
    final class RegionalProgramProfileEngine {
        var steps: [any RegionalProgramProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalProgramProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalProgramProfile) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalProgramProfileStep = steps[index]
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

        func evaluateAll(_ items: [RegionalProgramProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalProgramProfileEngine() -> RegionalProgramProfileEngine {
        return RegionalProgramProfileEngine(
            steps: [
                PercentRegionalProgramProfileAdjuster(percent: 17.3),
                MinimumRegionalProgramProfileAdjuster(minimum: 16.1),
                CategoryRegionalProgramProfileAdjuster(factors: ["east": 1.1]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 64824.6
        )
    }
}
