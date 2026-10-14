import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered study summary calculation.
    protocol TieredStudySummaryModifier {
        func describe() -> String
        func adjust(_ item: TieredStudySummary, value: Double) -> Double
    }

    final class FlaggedTieredStudySummaryAdjuster: TieredStudySummaryModifier {
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

        func adjust(_ item: TieredStudySummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredStudySummaryAdjuster: TieredStudySummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredStudySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredStudySummaryAdjuster: TieredStudySummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredStudySummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionTieredStudySummaryAdjuster: TieredStudySummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredStudySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredStudySummaryAdjuster: TieredStudySummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredStudySummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered study summary steps in order and keeps a trace of each.
    final class TieredStudySummaryEngine {
        var steps: [any TieredStudySummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredStudySummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredStudySummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredStudySummaryModifier = steps[index]
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

        func evaluateAll(_ items: [TieredStudySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredStudySummaryEngine(_ flags: Kit.Flags.Registry) -> TieredStudySummaryEngine {
        return TieredStudySummaryEngine(
            steps: [
                FlaggedTieredStudySummaryAdjuster(flags: flags, flag: "tiered-study-summary-manual", percent: 0.0),
                CapTieredStudySummaryAdjuster(cap: 13985.0),
                PercentTieredStudySummaryAdjuster(percent: -8.3),
                RegionTieredStudySummaryAdjuster(factors: ["central": 1.35, "south": 1.2]),
                TieredTieredStudySummaryAdjuster(bounds: [4809.0, 6788.0, 9485.0], rates: [0.81, 0.93, 1.08]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 65461.9
        )
    }
}
