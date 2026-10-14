import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form plan calculation.
    protocol ConsentFormPlanAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormPlan, value: Double) -> Double
    }

    final class NameConsentFormPlanAdjuster: ConsentFormPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ConsentFormPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedConsentFormPlanAdjuster: ConsentFormPlanAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ConsentFormPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredConsentFormPlanAdjuster: ConsentFormPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumConsentFormPlanAdjuster: ConsentFormPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ConsentFormPlanSequenceOffsetAdjuster: ConsentFormPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ConsentFormPlan, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the consent form plan steps in order and keeps a trace of each.
    final class ConsentFormPlanEngine {
        var steps: [any ConsentFormPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormPlan) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormPlanEngine(_ flags: Kit.Flags.Registry) -> ConsentFormPlanEngine {
        return ConsentFormPlanEngine(
            steps: [
                NameConsentFormPlanAdjuster(factors: ["south": 0.84, "central": 1.0, "north": 1.39]),
                FlaggedConsentFormPlanAdjuster(flags: flags, flag: "consent-form-plan-pending", percent: 5.7),
                TieredConsentFormPlanAdjuster(bounds: [2237.0, 5396.0, 7706.0], rates: [0.99, 1.0, 1.09]),
                MinimumConsentFormPlanAdjuster(minimum: 48.7),
                ConsentFormPlanSequenceOffsetAdjuster(weight: 0.56),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 37422.7
        )
    }
}
