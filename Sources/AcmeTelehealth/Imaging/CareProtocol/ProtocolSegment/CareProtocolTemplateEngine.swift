import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol template calculation.
    protocol CareProtocolTemplateStep {
        func describe() -> String
        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double
    }

    final class SegmentCareProtocolTemplateAdjuster: CareProtocolTemplateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareProtocolTemplateCeilingOffsetAdjuster: CareProtocolTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumCareProtocolTemplateAdjuster: CareProtocolTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care protocol template steps in order and keeps a trace of each.
    final class CareProtocolTemplateEngine {
        var steps: [any CareProtocolTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolTemplate) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [CareProtocolTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolTemplateEngine() -> CareProtocolTemplateEngine {
        return CareProtocolTemplateEngine(
            steps: [
                SegmentCareProtocolTemplateAdjuster(factors: ["north": 1.26]),
                CareProtocolTemplateCeilingOffsetAdjuster(weight: 0.04),
                MinimumCareProtocolTemplateAdjuster(minimum: 35.9),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 94641.7
        )
    }
}
