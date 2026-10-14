import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional outreach entry calculation.
    protocol RegionalOutreachEntryFactor {
        func describe() -> String
        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double
    }

    final class TieredRegionalOutreachEntryAdjuster: RegionalOutreachEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalOutreachEntryAdjuster: RegionalOutreachEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitRegionalOutreachEntryAdjuster: RegionalOutreachEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalOutreachEntryRevisionOffsetAdjuster: RegionalOutreachEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedRegionalOutreachEntryAdjuster: RegionalOutreachEntryFactor {
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

        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRegionalOutreachEntryAdjuster: RegionalOutreachEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOutreachEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional outreach entry steps in order and keeps a trace of each.
    final class RegionalOutreachEntryEngine {
        var steps: [any RegionalOutreachEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOutreachEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalOutreachEntry) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalOutreachEntryFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalOutreachEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalOutreachEntryEngine(_ flags: Kit.Flags.Registry) -> RegionalOutreachEntryEngine {
        return RegionalOutreachEntryEngine(
            steps: [
                TieredRegionalOutreachEntryAdjuster(bounds: [3872.0, 7478.0, 8546.0], rates: [0.89, 0.9, 0.84]),
                RoundingRegionalOutreachEntryAdjuster(step: 0.05),
                UnitRegionalOutreachEntryAdjuster(factors: ["west": 1.22]),
                RegionalOutreachEntryRevisionOffsetAdjuster(weight: 1.53),
                FlaggedRegionalOutreachEntryAdjuster(
                    flags: flags,
                    flag: "regional-outreach-entry-fallback",
                    percent: 5.2
                ),
                PercentRegionalOutreachEntryAdjuster(percent: -12.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 56330.5
        )
    }
}
