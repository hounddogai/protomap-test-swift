import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form variance calculation.
    protocol ConsentFormVarianceStep {
        func describe() -> String
        func adjust(_ item: ConsentFormVariance, value: Double) -> Double
    }

    final class LabelConsentFormVarianceAdjuster: ConsentFormVarianceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ConsentFormVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredConsentFormVarianceAdjuster: ConsentFormVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapConsentFormVarianceAdjuster: ConsentFormVarianceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentConsentFormVarianceAdjuster: ConsentFormVarianceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ConsentFormVarianceAttemptsOffsetAdjuster: ConsentFormVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ConsentFormVariance, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the consent form variance steps in order and keeps a trace of each.
    final class ConsentFormVarianceEngine {
        var steps: [any ConsentFormVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormVariance) -> Double {
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

        func evaluateAll(_ items: [ConsentFormVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormVarianceEngine() -> ConsentFormVarianceEngine {
        return ConsentFormVarianceEngine(
            steps: [
                LabelConsentFormVarianceAdjuster(factors: ["east": 1.0, "central": 0.97]),
                TieredConsentFormVarianceAdjuster(
                    bounds: [788.0, 957.0, 1616.0, 1984.0],
                    rates: [0.96, 1.14, 1.0, 1.16]
                ),
                CapConsentFormVarianceAdjuster(cap: 19175.0),
                PercentConsentFormVarianceAdjuster(percent: 4.2),
                ConsentFormVarianceAttemptsOffsetAdjuster(weight: 1.49),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 1313.8
        )
    }
}
