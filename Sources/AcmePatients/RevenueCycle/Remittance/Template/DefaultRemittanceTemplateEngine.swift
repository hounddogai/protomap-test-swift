import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default remittance template calculation.
    protocol DefaultRemittanceTemplateFactor {
        func describe() -> String
        func adjust(_ item: DefaultRemittanceTemplate, value: Double) -> Double
    }

    final class PercentDefaultRemittanceTemplateAdjuster: DefaultRemittanceTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRemittanceTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultRemittanceTemplateAdjuster: DefaultRemittanceTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultRemittanceTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultRemittanceTemplateAdjuster: DefaultRemittanceTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRemittanceTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default remittance template steps in order and keeps a trace of each.
    final class DefaultRemittanceTemplateEngine {
        var steps: [any DefaultRemittanceTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRemittanceTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultRemittanceTemplate) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [DefaultRemittanceTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultRemittanceTemplateEngine() -> DefaultRemittanceTemplateEngine {
        return DefaultRemittanceTemplateEngine(
            steps: [
                PercentDefaultRemittanceTemplateAdjuster(percent: 8.2),
                CapDefaultRemittanceTemplateAdjuster(cap: 26598.0),
                RoundingDefaultRemittanceTemplateAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 19144.6
        )
    }
}
