import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped outreach template calculation.
    protocol CappedOutreachTemplateFactor {
        func describe() -> String
        func adjust(_ item: CappedOutreachTemplate, value: Double) -> Double
    }

    final class CapCappedOutreachTemplateAdjuster: CappedOutreachTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedOutreachTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedOutreachTemplateAmountOffsetAdjuster: CappedOutreachTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CappedOutreachTemplate, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class SourceCappedOutreachTemplateAdjuster: CappedOutreachTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CappedOutreachTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedOutreachTemplateAdjuster: CappedOutreachTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedOutreachTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped outreach template steps in order and keeps a trace of each.
    final class CappedOutreachTemplateEngine {
        var steps: [any CappedOutreachTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedOutreachTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedOutreachTemplate) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedOutreachTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [CappedOutreachTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedOutreachTemplateEngine() -> CappedOutreachTemplateEngine {
        return CappedOutreachTemplateEngine(
            steps: [
                CapCappedOutreachTemplateAdjuster(cap: 14197.0),
                CappedOutreachTemplateAmountOffsetAdjuster(weight: 0.61),
                SourceCappedOutreachTemplateAdjuster(factors: ["online": 1.12]),
                RoundingCappedOutreachTemplateAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 65683.5
        )
    }
}
