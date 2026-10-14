import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual care protocol template calculation.
    protocol ManualCareProtocolTemplateFactor {
        func describe() -> String
        func adjust(_ item: ManualCareProtocolTemplate, value: Double) -> Double
    }

    final class RoundingManualCareProtocolTemplateAdjuster: ManualCareProtocolTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCareProtocolTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentManualCareProtocolTemplateAdjuster: ManualCareProtocolTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareProtocolTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualCareProtocolTemplateAdjuster: ManualCareProtocolTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareProtocolTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualCareProtocolTemplateAdjuster: ManualCareProtocolTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCareProtocolTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual care protocol template steps in order and keeps a trace of each.
    final class ManualCareProtocolTemplateEngine {
        var steps: [any ManualCareProtocolTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareProtocolTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualCareProtocolTemplate) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ManualCareProtocolTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualCareProtocolTemplateEngine() -> ManualCareProtocolTemplateEngine {
        return ManualCareProtocolTemplateEngine(
            steps: [
                RoundingManualCareProtocolTemplateAdjuster(step: 0.1),
                PercentManualCareProtocolTemplateAdjuster(percent: -24.4),
                MinimumManualCareProtocolTemplateAdjuster(minimum: 11.9),
                CapManualCareProtocolTemplateAdjuster(cap: 15609.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 34419.7
        )
    }
}
