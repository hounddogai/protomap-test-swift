import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility entry calculation.
    protocol EligibilityEntryModifier {
        func describe() -> String
        func adjust(_ item: EligibilityEntry, value: Double) -> Double
    }

    final class EligibilityEntrySequenceOffsetAdjuster: EligibilityEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: EligibilityEntry, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class PercentEligibilityEntryAdjuster: EligibilityEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredEligibilityEntryAdjuster: EligibilityEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedEligibilityEntryAdjuster: EligibilityEntryModifier {
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

        func adjust(_ item: EligibilityEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumEligibilityEntryAdjuster: EligibilityEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameEligibilityEntryAdjuster: EligibilityEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: EligibilityEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility entry steps in order and keeps a trace of each.
    final class EligibilityEntryEngine {
        var steps: [any EligibilityEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityEntry) -> Double {
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

        func evaluateAll(_ items: [EligibilityEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityEntryEngine(_ flags: Kit.Flags.Registry) -> EligibilityEntryEngine {
        return EligibilityEntryEngine(
            steps: [
                EligibilityEntrySequenceOffsetAdjuster(weight: 1.52),
                PercentEligibilityEntryAdjuster(percent: -18.2),
                TieredEligibilityEntryAdjuster(bounds: [3356.0, 5993.0], rates: [0.83, 1.14]),
                FlaggedEligibilityEntryAdjuster(flags: flags, flag: "eligibility-entry-default", percent: -4.0),
                MinimumEligibilityEntryAdjuster(minimum: 5.8),
                NameEligibilityEntryAdjuster(factors: ["north": 1.17, "west": 1.06, "central": 0.77]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 71906.6
        )
    }
}
