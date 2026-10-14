import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning template calculation.
    protocol CleaningTemplateStep {
        func describe() -> String
        func adjust(_ item: CleaningTemplate, value: Double) -> Double
    }

    final class PercentCleaningTemplateAdjuster: CleaningTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionCleaningTemplateAdjuster: CleaningTemplateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CleaningTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCleaningTemplateAdjuster: CleaningTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CleaningTemplateCapacityOffsetAdjuster: CleaningTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: CleaningTemplate, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class CapCleaningTemplateAdjuster: CleaningTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the cleaning template steps in order and keeps a trace of each.
    final class CleaningTemplateEngine {
        var steps: [any CleaningTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningTemplate) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [CleaningTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningTemplateEngine() -> CleaningTemplateEngine {
        return CleaningTemplateEngine(
            steps: [
                PercentCleaningTemplateAdjuster(percent: 20.3),
                RegionCleaningTemplateAdjuster(factors: ["west": 1.06, "retail": 1.2]),
                RoundingCleaningTemplateAdjuster(step: 0.1),
                CleaningTemplateCapacityOffsetAdjuster(weight: 0.77),
                CapCleaningTemplateAdjuster(cap: 30848.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 49615.5
        )
    }
}
