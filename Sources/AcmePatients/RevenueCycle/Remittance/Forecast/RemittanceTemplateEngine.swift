import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance template calculation.
    protocol RemittanceTemplateStep {
        func describe() -> String
        func adjust(_ item: RemittanceTemplate, value: Double) -> Double
    }

    final class TitleRemittanceTemplateAdjuster: RemittanceTemplateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RemittanceTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRemittanceTemplateAdjuster: RemittanceTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRemittanceTemplateAdjuster: RemittanceTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRemittanceTemplateAdjuster: RemittanceTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance template steps in order and keeps a trace of each.
    final class RemittanceTemplateEngine {
        var steps: [any RemittanceTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceTemplate) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RemittanceTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceTemplateEngine() -> RemittanceTemplateEngine {
        return RemittanceTemplateEngine(
            steps: [
                TitleRemittanceTemplateAdjuster(factors: ["online": 1.02, "central": 1.04, "east": 1.22]),
                RoundingRemittanceTemplateAdjuster(step: 0.05),
                PercentRemittanceTemplateAdjuster(percent: -8.0),
                CapRemittanceTemplateAdjuster(cap: 28606.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 66354.3
        )
    }
}
