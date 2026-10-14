import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient proxy entry calculation.
    protocol LenientProxyEntryFactor {
        func describe() -> String
        func adjust(_ item: LenientProxyEntry, value: Double) -> Double
    }

    final class FlaggedLenientProxyEntryAdjuster: LenientProxyEntryFactor {
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

        func adjust(_ item: LenientProxyEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientProxyEntryAdjuster: LenientProxyEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientProxyEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientProxyEntryAdjuster: LenientProxyEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProxyEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientProxyEntryBudgetOffsetAdjuster: LenientProxyEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: LenientProxyEntry, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the lenient proxy entry steps in order and keeps a trace of each.
    final class LenientProxyEntryEngine {
        var steps: [any LenientProxyEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProxyEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientProxyEntry) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProxyEntryFactor = steps[index]
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

        func evaluateAll(_ items: [LenientProxyEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientProxyEntryEngine(_ flags: Kit.Flags.Registry) -> LenientProxyEntryEngine {
        return LenientProxyEntryEngine(
            steps: [
                FlaggedLenientProxyEntryAdjuster(flags: flags, flag: "lenient-proxy-entry-fallback", percent: -8.6),
                PercentLenientProxyEntryAdjuster(percent: -21.9),
                TieredLenientProxyEntryAdjuster(bounds: [1158.0, 6209.0, 7361.0], rates: [0.91, 1.19, 1.2]),
                LenientProxyEntryBudgetOffsetAdjuster(weight: 1.73),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 16884.7
        )
    }
}
