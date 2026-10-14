import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy census tier calculation.
    protocol LegacyCensusTierModifier {
        func describe() -> String
        func adjust(_ item: LegacyCensusTier, value: Double) -> Double
    }

    final class FlaggedLegacyCensusTierAdjuster: LegacyCensusTierModifier {
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

        func adjust(_ item: LegacyCensusTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyCensusTierAdjuster: LegacyCensusTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCensusTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyCensusTierAdjuster: LegacyCensusTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCensusTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyCensusTierAdjuster: LegacyCensusTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyCensusTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelLegacyCensusTierAdjuster: LegacyCensusTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyCensusTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy census tier steps in order and keeps a trace of each.
    final class LegacyCensusTierEngine {
        var steps: [any LegacyCensusTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCensusTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyCensusTier) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCensusTierModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyCensusTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyCensusTierEngine(_ flags: Kit.Flags.Registry) -> LegacyCensusTierEngine {
        return LegacyCensusTierEngine(
            steps: [
                FlaggedLegacyCensusTierAdjuster(flags: flags, flag: "legacy-census-tier-global", percent: -6.6),
                TieredLegacyCensusTierAdjuster(bounds: [4022.0, 8852.0], rates: [1.02, 0.96]),
                MinimumLegacyCensusTierAdjuster(minimum: 20.1),
                PercentLegacyCensusTierAdjuster(percent: 10.4),
                LabelLegacyCensusTierAdjuster(factors: ["central": 1.32, "south": 1.02]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 92649.3
        )
    }
}
