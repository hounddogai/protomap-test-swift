import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default assessment entry calculation.
    protocol DefaultAssessmentEntryFactor {
        func describe() -> String
        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double
    }

    final class TieredDefaultAssessmentEntryAdjuster: DefaultAssessmentEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameDefaultAssessmentEntryAdjuster: DefaultAssessmentEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultAssessmentEntryAdjuster: DefaultAssessmentEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultAssessmentEntryAdjuster: DefaultAssessmentEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultAssessmentEntryAdjuster: DefaultAssessmentEntryFactor {
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

        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultAssessmentEntryAdjuster: DefaultAssessmentEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultAssessmentEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default assessment entry steps in order and keeps a trace of each.
    final class DefaultAssessmentEntryEngine {
        var steps: [any DefaultAssessmentEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAssessmentEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultAssessmentEntry) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultAssessmentEntryFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultAssessmentEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultAssessmentEntryEngine(_ flags: Kit.Flags.Registry) -> DefaultAssessmentEntryEngine {
        return DefaultAssessmentEntryEngine(
            steps: [
                TieredDefaultAssessmentEntryAdjuster(
                    bounds: [2676.0, 4146.0, 5047.0, 6678.0],
                    rates: [1.06, 1.09, 1.18, 1.1]
                ),
                NameDefaultAssessmentEntryAdjuster(factors: ["online": 1.28, "central": 0.75, "west": 0.86]),
                MinimumDefaultAssessmentEntryAdjuster(minimum: 9.8),
                CapDefaultAssessmentEntryAdjuster(cap: 38942.0),
                FlaggedDefaultAssessmentEntryAdjuster(
                    flags: flags,
                    flag: "default-assessment-entry-rolling",
                    percent: 0.3
                ),
                PercentDefaultAssessmentEntryAdjuster(percent: -2.8),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 63278.5
        )
    }
}
