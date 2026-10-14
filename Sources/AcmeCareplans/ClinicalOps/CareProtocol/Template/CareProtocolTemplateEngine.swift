import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol template calculation.
    protocol CareProtocolTemplateModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double
    }

    final class MinimumCareProtocolTemplateAdjuster: CareProtocolTemplateModifier {
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

    final class CapCareProtocolTemplateAdjuster: CareProtocolTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCareProtocolTemplateAdjuster: CareProtocolTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameCareProtocolTemplateAdjuster: CareProtocolTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCareProtocolTemplateAdjuster: CareProtocolTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol template steps in order and keeps a trace of each.
    final class CareProtocolTemplateEngine {
        var steps: [any CareProtocolTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolTemplate) -> Double {
            var current = item.measuredValue()
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
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolTemplateEngine() -> CareProtocolTemplateEngine {
        return CareProtocolTemplateEngine(
            steps: [
                MinimumCareProtocolTemplateAdjuster(minimum: 38.6),
                CapCareProtocolTemplateAdjuster(cap: 5628.0),
                RoundingCareProtocolTemplateAdjuster(step: 0.05),
                NameCareProtocolTemplateAdjuster(factors: ["central": 1.26, "online": 0.96]),
                PercentCareProtocolTemplateAdjuster(percent: -2.9),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 53292.3
        )
    }
}
