import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal care protocol baseline calculation.
    protocol SeasonalCareProtocolBaselineStep {
        func describe() -> String
        func adjust(_ item: SeasonalCareProtocolBaseline, value: Double) -> Double
    }

    final class CapSeasonalCareProtocolBaselineAdjuster: SeasonalCareProtocolBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalCareProtocolBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSeasonalCareProtocolBaselineAdjuster: SeasonalCareProtocolBaselineStep {
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

        func adjust(_ item: SeasonalCareProtocolBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalCareProtocolBaselineAdjuster: SeasonalCareProtocolBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCareProtocolBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal care protocol baseline steps in order and keeps a trace of each.
    final class SeasonalCareProtocolBaselineEngine {
        var steps: [any SeasonalCareProtocolBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareProtocolBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalCareProtocolBaseline) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [SeasonalCareProtocolBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareProtocolBaselineEngine(_ flags: Kit.Flags.Registry) -> SeasonalCareProtocolBaselineEngine {
        return SeasonalCareProtocolBaselineEngine(
            steps: [
                CapSeasonalCareProtocolBaselineAdjuster(cap: 35265.0),
                FlaggedSeasonalCareProtocolBaselineAdjuster(
                    flags: flags,
                    flag: "seasonal-care-protocol-baseline-tiered",
                    percent: -9.9
                ),
                MinimumSeasonalCareProtocolBaselineAdjuster(minimum: 33.8),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 12940.3
        )
    }
}
