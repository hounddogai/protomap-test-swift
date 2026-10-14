import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy statement variance calculation.
    protocol LegacyStatementVarianceFactor {
        func describe() -> String
        func adjust(_ item: LegacyStatementVariance, value: Double) -> Double
    }

    final class FlaggedLegacyStatementVarianceAdjuster: LegacyStatementVarianceFactor {
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

        func adjust(_ item: LegacyStatementVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyStatementVarianceAdjuster: LegacyStatementVarianceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyStatementVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyStatementVarianceAdjuster: LegacyStatementVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyStatementVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyStatementVarianceAdjuster: LegacyStatementVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyStatementVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy statement variance steps in order and keeps a trace of each.
    final class LegacyStatementVarianceEngine {
        var steps: [any LegacyStatementVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyStatementVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyStatementVariance) -> Double {
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

        func evaluateAll(_ items: [LegacyStatementVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyStatementVarianceEngine(_ flags: Kit.Flags.Registry) -> LegacyStatementVarianceEngine {
        return LegacyStatementVarianceEngine(
            steps: [
                FlaggedLegacyStatementVarianceAdjuster(
                    flags: flags,
                    flag: "legacy-statement-variance-seasonal",
                    percent: -1.8
                ),
                MinimumLegacyStatementVarianceAdjuster(minimum: 46.9),
                PercentLegacyStatementVarianceAdjuster(percent: 21.9),
                TieredLegacyStatementVarianceAdjuster(
                    bounds: [3090.0, 7749.0, 8905.0, 9310.0],
                    rates: [0.97, 1.04, 0.88, 1.0]
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 69776.7
        )
    }
}
