import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped panel digest calculation.
    protocol CappedPanelDigestAdjuster {
        func describe() -> String
        func adjust(_ item: CappedPanelDigest, value: Double) -> Double
    }

    final class FlaggedCappedPanelDigestAdjuster: CappedPanelDigestAdjuster {
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

        func adjust(_ item: CappedPanelDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedPanelDigestAdjuster: CappedPanelDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedPanelDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedPanelDigestAdjuster: CappedPanelDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedPanelDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedPanelDigestAdjuster: CappedPanelDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedPanelDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped panel digest steps in order and keeps a trace of each.
    final class CappedPanelDigestEngine {
        var steps: [any CappedPanelDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedPanelDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedPanelDigest) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [CappedPanelDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedPanelDigestEngine(_ flags: Kit.Flags.Registry) -> CappedPanelDigestEngine {
        return CappedPanelDigestEngine(
            steps: [
                FlaggedCappedPanelDigestAdjuster(flags: flags, flag: "capped-panel-digest-lenient", percent: -6.6),
                MinimumCappedPanelDigestAdjuster(minimum: 44.6),
                PercentCappedPanelDigestAdjuster(percent: 14.5),
                TieredCappedPanelDigestAdjuster(
                    bounds: [656.0, 2912.0, 7073.0, 7631.0],
                    rates: [0.98, 0.86, 1.03, 0.83]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 19674.3
        )
    }
}
