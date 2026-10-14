import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation template calculation.
    protocol RevocationTemplateStep {
        func describe() -> String
        func adjust(_ item: RevocationTemplate, value: Double) -> Double
    }

    final class RoundingRevocationTemplateAdjuster: RevocationTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RevocationTemplateDurationMinutesOffsetAdjuster: RevocationTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: RevocationTemplate, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredRevocationTemplateAdjuster: RevocationTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryRevocationTemplateAdjuster: RevocationTemplateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RevocationTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRevocationTemplateAdjuster: RevocationTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRevocationTemplateAdjuster: RevocationTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the revocation template steps in order and keeps a trace of each.
    final class RevocationTemplateEngine {
        var steps: [any RevocationTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RevocationTemplate) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [RevocationTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRevocationTemplateEngine() -> RevocationTemplateEngine {
        return RevocationTemplateEngine(
            steps: [
                RoundingRevocationTemplateAdjuster(step: 0.5),
                RevocationTemplateDurationMinutesOffsetAdjuster(weight: 1.04),
                TieredRevocationTemplateAdjuster(bounds: [5224.0, 8163.0], rates: [0.97, 0.97]),
                CountryRevocationTemplateAdjuster(factors: ["south": 1.36, "retail": 1.02]),
                PercentRevocationTemplateAdjuster(percent: 4.8),
                CapRevocationTemplateAdjuster(cap: 39662.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 9256.8
        )
    }
}
