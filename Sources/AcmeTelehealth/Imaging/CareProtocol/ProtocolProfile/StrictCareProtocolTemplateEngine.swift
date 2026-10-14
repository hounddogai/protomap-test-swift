import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict care protocol template calculation.
    protocol StrictCareProtocolTemplateFactor {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolTemplate, value: Double) -> Double
    }

    final class PercentStrictCareProtocolTemplateAdjuster: StrictCareProtocolTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCareProtocolTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictCareProtocolTemplateAdjuster: StrictCareProtocolTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictCareProtocolTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelStrictCareProtocolTemplateAdjuster: StrictCareProtocolTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictCareProtocolTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictCareProtocolTemplateAdjuster: StrictCareProtocolTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCareProtocolTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict care protocol template steps in order and keeps a trace of each.
    final class StrictCareProtocolTemplateEngine {
        var steps: [any StrictCareProtocolTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictCareProtocolTemplate) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [StrictCareProtocolTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolTemplateEngine() -> StrictCareProtocolTemplateEngine {
        return StrictCareProtocolTemplateEngine(
            steps: [
                PercentStrictCareProtocolTemplateAdjuster(percent: 4.2),
                CapStrictCareProtocolTemplateAdjuster(cap: 3562.0),
                LabelStrictCareProtocolTemplateAdjuster(factors: ["retail": 0.7]),
                RoundingStrictCareProtocolTemplateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 50966.1
        )
    }
}
