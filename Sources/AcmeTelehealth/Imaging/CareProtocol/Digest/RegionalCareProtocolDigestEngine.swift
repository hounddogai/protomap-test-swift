import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional care protocol digest calculation.
    protocol RegionalCareProtocolDigestModifier {
        func describe() -> String
        func adjust(_ item: RegionalCareProtocolDigest, value: Double) -> Double
    }

    final class RoundingRegionalCareProtocolDigestAdjuster: RegionalCareProtocolDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCareProtocolDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRegionalCareProtocolDigestAdjuster: RegionalCareProtocolDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalCareProtocolDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRegionalCareProtocolDigestAdjuster: RegionalCareProtocolDigestModifier {
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

        func adjust(_ item: RegionalCareProtocolDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalCareProtocolDigestAdjuster: RegionalCareProtocolDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCareProtocolDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional care protocol digest steps in order and keeps a trace of each.
    final class RegionalCareProtocolDigestEngine {
        var steps: [any RegionalCareProtocolDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareProtocolDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalCareProtocolDigest) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalCareProtocolDigestModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalCareProtocolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalCareProtocolDigestEngine(_ flags: Kit.Flags.Registry) -> RegionalCareProtocolDigestEngine {
        return RegionalCareProtocolDigestEngine(
            steps: [
                RoundingRegionalCareProtocolDigestAdjuster(step: 0.25),
                PercentRegionalCareProtocolDigestAdjuster(percent: -24.6),
                FlaggedRegionalCareProtocolDigestAdjuster(
                    flags: flags,
                    flag: "regional-care-protocol-digest-global",
                    percent: 6.9
                ),
                TieredRegionalCareProtocolDigestAdjuster(bounds: [6670.0, 6828.0], rates: [0.98, 0.9]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 27654.9
        )
    }
}
