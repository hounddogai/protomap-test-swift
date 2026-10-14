import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted consent form rollup calculation.
    protocol WeightedConsentFormRollupAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedConsentFormRollup, value: Double) -> Double
    }

    final class WeightedConsentFormRollupVersionOffsetAdjuster: WeightedConsentFormRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: WeightedConsentFormRollup, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class ChannelWeightedConsentFormRollupAdjuster: WeightedConsentFormRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: WeightedConsentFormRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedConsentFormRollupAdjuster: WeightedConsentFormRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedConsentFormRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedConsentFormRollupAdjuster: WeightedConsentFormRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedConsentFormRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedWeightedConsentFormRollupAdjuster: WeightedConsentFormRollupAdjuster {
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

        func adjust(_ item: WeightedConsentFormRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted consent form rollup steps in order and keeps a trace of each.
    final class WeightedConsentFormRollupEngine {
        var steps: [any WeightedConsentFormRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedConsentFormRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedConsentFormRollup) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [WeightedConsentFormRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedConsentFormRollupEngine(_ flags: Kit.Flags.Registry) -> WeightedConsentFormRollupEngine {
        return WeightedConsentFormRollupEngine(
            steps: [
                WeightedConsentFormRollupVersionOffsetAdjuster(weight: 0.99),
                ChannelWeightedConsentFormRollupAdjuster(factors: ["north": 0.92]),
                TieredWeightedConsentFormRollupAdjuster(
                    bounds: [5611.0, 5740.0, 5990.0, 8707.0],
                    rates: [0.94, 0.96, 0.96, 0.83]
                ),
                CapWeightedConsentFormRollupAdjuster(cap: 17706.0),
                FlaggedWeightedConsentFormRollupAdjuster(
                    flags: flags,
                    flag: "weighted-consent-form-rollup-strict",
                    percent: 3.7
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 50180.2
        )
    }
}
