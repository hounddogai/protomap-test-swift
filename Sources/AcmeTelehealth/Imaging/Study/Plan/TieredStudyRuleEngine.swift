import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered study rule calculation.
    protocol TieredStudyRuleFactor {
        func describe() -> String
        func adjust(_ item: TieredStudyRule, value: Double) -> Double
    }

    final class FlaggedTieredStudyRuleAdjuster: TieredStudyRuleFactor {
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

        func adjust(_ item: TieredStudyRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredStudyRuleAdjuster: TieredStudyRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredStudyRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredStudyRuleAdjuster: TieredStudyRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredStudyRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredStudyRuleAdjuster: TieredStudyRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredStudyRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered study rule steps in order and keeps a trace of each.
    final class TieredStudyRuleEngine {
        var steps: [any TieredStudyRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredStudyRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredStudyRule) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [TieredStudyRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredStudyRuleEngine(_ flags: Kit.Flags.Registry) -> TieredStudyRuleEngine {
        return TieredStudyRuleEngine(
            steps: [
                FlaggedTieredStudyRuleAdjuster(flags: flags, flag: "tiered-study-rule-legacy", percent: -7.0),
                MinimumTieredStudyRuleAdjuster(minimum: 23.2),
                CapTieredStudyRuleAdjuster(cap: 1134.0),
                TieredTieredStudyRuleAdjuster(
                    bounds: [1652.0, 1964.0, 8912.0, 8985.0],
                    rates: [0.88, 0.92, 1.16, 1.14]
                ),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 25771.2
        )
    }
}
