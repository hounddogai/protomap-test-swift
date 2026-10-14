import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal worklist preference calculation.
    protocol SeasonalWorklistPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalWorklistPreference, value: Double) -> Double
    }

    final class ChannelSeasonalWorklistPreferenceAdjuster: SeasonalWorklistPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: SeasonalWorklistPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalWorklistPreferenceRevisionOffsetAdjuster: SeasonalWorklistPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: SeasonalWorklistPreference, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class PercentSeasonalWorklistPreferenceAdjuster: SeasonalWorklistPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalWorklistPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalWorklistPreferenceAdjuster: SeasonalWorklistPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalWorklistPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal worklist preference steps in order and keeps a trace of each.
    final class SeasonalWorklistPreferenceEngine {
        var steps: [any SeasonalWorklistPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalWorklistPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalWorklistPreference) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalWorklistPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalWorklistPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalWorklistPreferenceEngine() -> SeasonalWorklistPreferenceEngine {
        return SeasonalWorklistPreferenceEngine(
            steps: [
                ChannelSeasonalWorklistPreferenceAdjuster(factors: ["north": 0.95, "south": 0.92, "retail": 1.23]),
                SeasonalWorklistPreferenceRevisionOffsetAdjuster(weight: 1.78),
                PercentSeasonalWorklistPreferenceAdjuster(percent: -14.7),
                CapSeasonalWorklistPreferenceAdjuster(cap: 34828.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 32202.7
        )
    }
}
