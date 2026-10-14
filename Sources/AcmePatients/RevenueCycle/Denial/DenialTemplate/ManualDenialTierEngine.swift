import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual denial tier calculation.
    protocol ManualDenialTierStep {
        func describe() -> String
        func adjust(_ item: ManualDenialTier, value: Double) -> Double
    }

    final class RoundingManualDenialTierAdjuster: ManualDenialTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDenialTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelManualDenialTierAdjuster: ManualDenialTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualDenialTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualDenialTierAdjuster: ManualDenialTierStep {
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

        func adjust(_ item: ManualDenialTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualDenialTierAdjuster: ManualDenialTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDenialTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualDenialTierAdjuster: ManualDenialTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDenialTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual denial tier steps in order and keeps a trace of each.
    final class ManualDenialTierEngine {
        var steps: [any ManualDenialTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDenialTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualDenialTier) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDenialTierStep = steps[index]
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

        func evaluateAll(_ items: [ManualDenialTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualDenialTierEngine(_ flags: Kit.Flags.Registry) -> ManualDenialTierEngine {
        return ManualDenialTierEngine(
            steps: [
                RoundingManualDenialTierAdjuster(step: 1.0),
                LabelManualDenialTierAdjuster(factors: ["south": 0.74]),
                FlaggedManualDenialTierAdjuster(flags: flags, flag: "manual-denial-tier-default", percent: 0.0),
                TieredManualDenialTierAdjuster(
                    bounds: [3391.0, 3965.0, 4270.0, 4540.0],
                    rates: [0.85, 0.9, 1.09, 1.01]
                ),
                CapManualDenialTierAdjuster(cap: 15385.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 46682.4
        )
    }
}
