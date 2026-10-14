import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy care protocol digest calculation.
    protocol LegacyCareProtocolDigestAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyCareProtocolDigest, value: Double) -> Double
    }

    final class TieredLegacyCareProtocolDigestAdjuster: LegacyCareProtocolDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCareProtocolDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLegacyCareProtocolDigestAdjuster: LegacyCareProtocolDigestAdjuster {
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

        func adjust(_ item: LegacyCareProtocolDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyCareProtocolDigestAdjuster: LegacyCareProtocolDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyCareProtocolDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LegacyCareProtocolDigestScoreOffsetAdjuster: LegacyCareProtocolDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LegacyCareProtocolDigest, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the legacy care protocol digest steps in order and keeps a trace of each.
    final class LegacyCareProtocolDigestEngine {
        var steps: [any LegacyCareProtocolDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCareProtocolDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyCareProtocolDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCareProtocolDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyCareProtocolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyCareProtocolDigestEngine(_ flags: Kit.Flags.Registry) -> LegacyCareProtocolDigestEngine {
        return LegacyCareProtocolDigestEngine(
            steps: [
                TieredLegacyCareProtocolDigestAdjuster(
                    bounds: [852.0, 2692.0, 5882.0, 5958.0],
                    rates: [0.94, 1.19, 0.93, 1.1]
                ),
                FlaggedLegacyCareProtocolDigestAdjuster(
                    flags: flags,
                    flag: "legacy-care-protocol-digest-manual",
                    percent: -1.2
                ),
                RoundingLegacyCareProtocolDigestAdjuster(step: 1.0),
                LegacyCareProtocolDigestScoreOffsetAdjuster(weight: 0.01),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 39293.1
        )
    }
}
