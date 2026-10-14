import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure template calculation.
    protocol DisclosureTemplateFactor {
        func describe() -> String
        func adjust(_ item: DisclosureTemplate, value: Double) -> Double
    }

    final class TieredDisclosureTemplateAdjuster: DisclosureTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDisclosureTemplateAdjuster: DisclosureTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DisclosureTemplateQuantityOffsetAdjuster: DisclosureTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DisclosureTemplate, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumDisclosureTemplateAdjuster: DisclosureTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceDisclosureTemplateAdjuster: DisclosureTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DisclosureTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure template steps in order and keeps a trace of each.
    final class DisclosureTemplateEngine {
        var steps: [any DisclosureTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [DisclosureTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureTemplateEngine() -> DisclosureTemplateEngine {
        return DisclosureTemplateEngine(
            steps: [
                TieredDisclosureTemplateAdjuster(
                    bounds: [1339.0, 1748.0, 2053.0, 7609.0],
                    rates: [0.95, 0.96, 1.19, 0.98]
                ),
                PercentDisclosureTemplateAdjuster(percent: -12.2),
                DisclosureTemplateQuantityOffsetAdjuster(weight: 0.51),
                MinimumDisclosureTemplateAdjuster(minimum: 11.5),
                SourceDisclosureTemplateAdjuster(factors: ["north": 1.1]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 71772.7
        )
    }
}
