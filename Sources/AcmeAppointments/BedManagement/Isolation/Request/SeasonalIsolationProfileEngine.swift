import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the seasonal isolation profile calculation.
    protocol SeasonalIsolationProfileFactor {
        func describe() -> String
        func adjust(_ item: SeasonalIsolationProfile, value: Double) -> Double
    }

    final class SeasonalIsolationProfileCeilingOffsetAdjuster: SeasonalIsolationProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: SeasonalIsolationProfile, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class LabelSeasonalIsolationProfileAdjuster: SeasonalIsolationProfileFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalIsolationProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalIsolationProfileAdjuster: SeasonalIsolationProfileFactor {
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

        func adjust(_ item: SeasonalIsolationProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal isolation profile steps in order and keeps a trace of each.
    final class SeasonalIsolationProfileEngine {
        var steps: [any SeasonalIsolationProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalIsolationProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalIsolationProfile) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SeasonalIsolationProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalIsolationProfileEngine(_ flags: Kit.Flags.Registry) -> SeasonalIsolationProfileEngine {
        return SeasonalIsolationProfileEngine(
            steps: [
                SeasonalIsolationProfileCeilingOffsetAdjuster(weight: 1.66),
                LabelSeasonalIsolationProfileAdjuster(factors: ["south": 1.19, "central": 0.86, "north": 0.89]),
                FlaggedSeasonalIsolationProfileAdjuster(
                    flags: flags,
                    flag: "seasonal-isolation-profile-tiered",
                    percent: 3.5
                ),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 89858.5
        )
    }
}
