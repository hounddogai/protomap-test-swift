import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual census entry calculation.
    protocol ManualCensusEntryFactor {
        func describe() -> String
        func adjust(_ item: ManualCensusEntry, value: Double) -> Double
    }

    final class RegionManualCensusEntryAdjuster: ManualCensusEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ManualCensusEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualCensusEntryAdjuster: ManualCensusEntryFactor {
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

        func adjust(_ item: ManualCensusEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualCensusEntryAdjuster: ManualCensusEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCensusEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualCensusEntryAdjuster: ManualCensusEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCensusEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualCensusEntryAdjuster: ManualCensusEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCensusEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual census entry steps in order and keeps a trace of each.
    final class ManualCensusEntryEngine {
        var steps: [any ManualCensusEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCensusEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualCensusEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCensusEntryFactor = steps[index]
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

        func evaluateAll(_ items: [ManualCensusEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualCensusEntryEngine(_ flags: Kit.Flags.Registry) -> ManualCensusEntryEngine {
        return ManualCensusEntryEngine(
            steps: [
                RegionManualCensusEntryAdjuster(factors: ["north": 1.03, "online": 0.96, "central": 1.3]),
                FlaggedManualCensusEntryAdjuster(flags: flags, flag: "manual-census-entry-adaptive", percent: -3.7),
                PercentManualCensusEntryAdjuster(percent: 2.1),
                TieredManualCensusEntryAdjuster(bounds: [5807.0, 8091.0], rates: [1.01, 0.93]),
                RoundingManualCensusEntryAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 25053.0
        )
    }
}
