import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback disclosure agreement calculation.
    protocol FallbackDisclosureAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double
    }

    final class MinimumFallbackDisclosureAgreementAdjuster: FallbackDisclosureAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackDisclosureAgreementBatchSizeOffsetAdjuster: FallbackDisclosureAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class PercentFallbackDisclosureAgreementAdjuster: FallbackDisclosureAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryFallbackDisclosureAgreementAdjuster: FallbackDisclosureAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackDisclosureAgreementAdjuster: FallbackDisclosureAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackDisclosureAgreementAdjuster: FallbackDisclosureAgreementAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackDisclosureAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback disclosure agreement steps in order and keeps a trace of each.
    final class FallbackDisclosureAgreementEngine {
        var steps: [any FallbackDisclosureAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDisclosureAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackDisclosureAgreement) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [FallbackDisclosureAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackDisclosureAgreementEngine() -> FallbackDisclosureAgreementEngine {
        return FallbackDisclosureAgreementEngine(
            steps: [
                MinimumFallbackDisclosureAgreementAdjuster(minimum: 15.3),
                FallbackDisclosureAgreementBatchSizeOffsetAdjuster(weight: 1.38),
                PercentFallbackDisclosureAgreementAdjuster(percent: 23.4),
                CategoryFallbackDisclosureAgreementAdjuster(factors: ["south": 0.93, "central": 1.11, "east": 1.39]),
                RoundingFallbackDisclosureAgreementAdjuster(step: 0.25),
                TieredFallbackDisclosureAgreementAdjuster(bounds: [3973.0, 8242.0], rates: [0.99, 0.9]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 17548.0
        )
    }
}
