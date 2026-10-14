import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered denial template calculation.
    protocol TieredDenialTemplateFactor {
        func describe() -> String
        func adjust(_ item: TieredDenialTemplate, value: Double) -> Double
    }

    final class CapTieredDenialTemplateAdjuster: TieredDenialTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredDenialTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredDenialTemplateAdjuster: TieredDenialTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredDenialTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleTieredDenialTemplateAdjuster: TieredDenialTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredDenialTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredDenialTemplateAdjuster: TieredDenialTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredDenialTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered denial template steps in order and keeps a trace of each.
    final class TieredDenialTemplateEngine {
        var steps: [any TieredDenialTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredDenialTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredDenialTemplate) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [TieredDenialTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredDenialTemplateEngine() -> TieredDenialTemplateEngine {
        return TieredDenialTemplateEngine(
            steps: [
                CapTieredDenialTemplateAdjuster(cap: 12902.0),
                MinimumTieredDenialTemplateAdjuster(minimum: 6.4),
                TitleTieredDenialTemplateAdjuster(factors: ["retail": 1.24]),
                TieredTieredDenialTemplateAdjuster(bounds: [303.0, 3738.0, 4011.0], rates: [1.14, 0.97, 0.96]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 78008.5
        )
    }
}
