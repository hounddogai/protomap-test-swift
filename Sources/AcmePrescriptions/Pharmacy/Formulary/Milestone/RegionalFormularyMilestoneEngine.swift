import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional formulary milestone calculation.
    protocol RegionalFormularyMilestoneStep {
        func describe() -> String
        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double
    }

    final class FlaggedRegionalFormularyMilestoneAdjuster: RegionalFormularyMilestoneStep {
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

        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleRegionalFormularyMilestoneAdjuster: RegionalFormularyMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalFormularyMilestoneAdjuster: RegionalFormularyMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalFormularyMilestoneAdjuster: RegionalFormularyMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRegionalFormularyMilestoneAdjuster: RegionalFormularyMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionalFormularyMilestoneRetriesOffsetAdjuster: RegionalFormularyMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RegionalFormularyMilestone, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the regional formulary milestone steps in order and keeps a trace of each.
    final class RegionalFormularyMilestoneEngine {
        var steps: [any RegionalFormularyMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFormularyMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalFormularyMilestone) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RegionalFormularyMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalFormularyMilestoneEngine(_ flags: Kit.Flags.Registry) -> RegionalFormularyMilestoneEngine {
        return RegionalFormularyMilestoneEngine(
            steps: [
                FlaggedRegionalFormularyMilestoneAdjuster(
                    flags: flags,
                    flag: "regional-formulary-milestone-global",
                    percent: -7.7
                ),
                LocaleRegionalFormularyMilestoneAdjuster(factors: ["retail": 0.89]),
                PercentRegionalFormularyMilestoneAdjuster(percent: -20.4),
                TieredRegionalFormularyMilestoneAdjuster(
                    bounds: [1550.0, 4599.0, 7055.0, 9354.0],
                    rates: [1.01, 1.04, 0.9, 1.05]
                ),
                MinimumRegionalFormularyMilestoneAdjuster(minimum: 20.1),
                RegionalFormularyMilestoneRetriesOffsetAdjuster(weight: 1.88),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 91705.2
        )
    }
}
