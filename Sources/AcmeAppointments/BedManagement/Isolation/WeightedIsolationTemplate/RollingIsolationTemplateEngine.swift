import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling isolation template calculation.
    protocol RollingIsolationTemplateModifier {
        func describe() -> String
        func adjust(_ item: RollingIsolationTemplate, value: Double) -> Double
    }

    final class CountryRollingIsolationTemplateAdjuster: RollingIsolationTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RollingIsolationTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingIsolationTemplateRatioOffsetAdjuster: RollingIsolationTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: RollingIsolationTemplate, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingRollingIsolationTemplateAdjuster: RollingIsolationTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingIsolationTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling isolation template steps in order and keeps a trace of each.
    final class RollingIsolationTemplateEngine {
        var steps: [any RollingIsolationTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingIsolationTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingIsolationTemplate) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingIsolationTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [RollingIsolationTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingIsolationTemplateEngine() -> RollingIsolationTemplateEngine {
        return RollingIsolationTemplateEngine(
            steps: [
                CountryRollingIsolationTemplateAdjuster(factors: ["east": 1.11, "west": 1.16]),
                RollingIsolationTemplateRatioOffsetAdjuster(weight: 1.24),
                RoundingRollingIsolationTemplateAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 76862.4
        )
    }
}
