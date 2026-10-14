import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal witness notice calculation.
    protocol SeasonalWitnessNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalWitnessNotice, value: Double) -> Double
    }

    final class NameSeasonalWitnessNoticeAdjuster: SeasonalWitnessNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalWitnessNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSeasonalWitnessNoticeAdjuster: SeasonalWitnessNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalWitnessNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalWitnessNoticeAdjuster: SeasonalWitnessNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalWitnessNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalWitnessNoticeAdjuster: SeasonalWitnessNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalWitnessNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSeasonalWitnessNoticeAdjuster: SeasonalWitnessNoticeAdjuster {
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

        func adjust(_ item: SeasonalWitnessNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal witness notice steps in order and keeps a trace of each.
    final class SeasonalWitnessNoticeEngine {
        var steps: [any SeasonalWitnessNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalWitnessNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalWitnessNotice) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [SeasonalWitnessNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalWitnessNoticeEngine(_ flags: Kit.Flags.Registry) -> SeasonalWitnessNoticeEngine {
        return SeasonalWitnessNoticeEngine(
            steps: [
                NameSeasonalWitnessNoticeAdjuster(factors: ["east": 0.78]),
                RoundingSeasonalWitnessNoticeAdjuster(step: 0.25),
                PercentSeasonalWitnessNoticeAdjuster(percent: 4.4),
                CapSeasonalWitnessNoticeAdjuster(cap: 34616.0),
                FlaggedSeasonalWitnessNoticeAdjuster(
                    flags: flags,
                    flag: "seasonal-witness-notice-strict",
                    percent: 2.0
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 46417.4
        )
    }
}
