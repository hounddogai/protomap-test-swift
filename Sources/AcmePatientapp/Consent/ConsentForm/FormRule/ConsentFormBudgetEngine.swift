import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form budget calculation.
    protocol ConsentFormBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormBudget, value: Double) -> Double
    }

    final class FlaggedConsentFormBudgetAdjuster: ConsentFormBudgetAdjuster {
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

        func adjust(_ item: ConsentFormBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredConsentFormBudgetAdjuster: ConsentFormBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapConsentFormBudgetAdjuster: ConsentFormBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingConsentFormBudgetAdjuster: ConsentFormBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ConsentFormBudgetMarginOffsetAdjuster: ConsentFormBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ConsentFormBudget, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the consent form budget steps in order and keeps a trace of each.
    final class ConsentFormBudgetEngine {
        var steps: [any ConsentFormBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormBudget) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ConsentFormBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormBudgetEngine(_ flags: Kit.Flags.Registry) -> ConsentFormBudgetEngine {
        return ConsentFormBudgetEngine(
            steps: [
                FlaggedConsentFormBudgetAdjuster(flags: flags, flag: "consent-form-budget-strict", percent: -5.7),
                TieredConsentFormBudgetAdjuster(
                    bounds: [1776.0, 2772.0, 2977.0, 9355.0],
                    rates: [1.14, 0.86, 1.14, 1.16]
                ),
                CapConsentFormBudgetAdjuster(cap: 8149.0),
                RoundingConsentFormBudgetAdjuster(step: 0.25),
                ConsentFormBudgetMarginOffsetAdjuster(weight: 0.17),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 16971.8
        )
    }
}
