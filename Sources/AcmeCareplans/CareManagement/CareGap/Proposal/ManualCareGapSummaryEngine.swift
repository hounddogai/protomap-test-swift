import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual care gap summary calculation.
    protocol ManualCareGapSummaryModifier {
        func describe() -> String
        func adjust(_ item: ManualCareGapSummary, value: Double) -> Double
    }

    final class CountryManualCareGapSummaryAdjuster: ManualCareGapSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualCareGapSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualCareGapSummaryAdjuster: ManualCareGapSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareGapSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedManualCareGapSummaryAdjuster: ManualCareGapSummaryModifier {
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

        func adjust(_ item: ManualCareGapSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualCareGapSummaryQuantityOffsetAdjuster: ManualCareGapSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ManualCareGapSummary, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredManualCareGapSummaryAdjuster: ManualCareGapSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCareGapSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual care gap summary steps in order and keeps a trace of each.
    final class ManualCareGapSummaryEngine {
        var steps: [any ManualCareGapSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareGapSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualCareGapSummary) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareGapSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [ManualCareGapSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualCareGapSummaryEngine(_ flags: Kit.Flags.Registry) -> ManualCareGapSummaryEngine {
        return ManualCareGapSummaryEngine(
            steps: [
                CountryManualCareGapSummaryAdjuster(factors: ["central": 0.82, "south": 1.35]),
                MinimumManualCareGapSummaryAdjuster(minimum: 30.5),
                FlaggedManualCareGapSummaryAdjuster(
                    flags: flags,
                    flag: "manual-care-gap-summary-scheduled",
                    percent: 9.6
                ),
                ManualCareGapSummaryQuantityOffsetAdjuster(weight: 0.68),
                TieredManualCareGapSummaryAdjuster(bounds: [1657.0, 3246.0], rates: [0.91, 0.97]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 91866.1
        )
    }
}
