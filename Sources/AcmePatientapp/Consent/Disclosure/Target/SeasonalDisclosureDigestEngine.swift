import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal disclosure digest calculation.
    protocol SeasonalDisclosureDigestAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalDisclosureDigest, value: Double) -> Double
    }

    final class PercentSeasonalDisclosureDigestAdjuster: SeasonalDisclosureDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalDisclosureDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleSeasonalDisclosureDigestAdjuster: SeasonalDisclosureDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalDisclosureDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalDisclosureDigestAdjuster: SeasonalDisclosureDigestAdjuster {
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

        func adjust(_ item: SeasonalDisclosureDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalDisclosureDigestAdjuster: SeasonalDisclosureDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalDisclosureDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalDisclosureDigestAdjuster: SeasonalDisclosureDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalDisclosureDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal disclosure digest steps in order and keeps a trace of each.
    final class SeasonalDisclosureDigestEngine {
        var steps: [any SeasonalDisclosureDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalDisclosureDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalDisclosureDigest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalDisclosureDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalDisclosureDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalDisclosureDigestEngine(_ flags: Kit.Flags.Registry) -> SeasonalDisclosureDigestEngine {
        return SeasonalDisclosureDigestEngine(
            steps: [
                PercentSeasonalDisclosureDigestAdjuster(percent: -9.8),
                TitleSeasonalDisclosureDigestAdjuster(factors: ["north": 0.83, "online": 1.21]),
                FlaggedSeasonalDisclosureDigestAdjuster(
                    flags: flags,
                    flag: "seasonal-disclosure-digest-lenient",
                    percent: -2.0
                ),
                RoundingSeasonalDisclosureDigestAdjuster(step: 1.0),
                CapSeasonalDisclosureDigestAdjuster(cap: 5429.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 88709.2
        )
    }
}
