import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default remittance digest calculation.
    protocol DefaultRemittanceDigestFactor {
        func describe() -> String
        func adjust(_ item: DefaultRemittanceDigest, value: Double) -> Double
    }

    final class RoundingDefaultRemittanceDigestAdjuster: DefaultRemittanceDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRemittanceDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultRemittanceDigestAdjuster: DefaultRemittanceDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRemittanceDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultRemittanceDigestAdjuster: DefaultRemittanceDigestFactor {
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

        func adjust(_ item: DefaultRemittanceDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default remittance digest steps in order and keeps a trace of each.
    final class DefaultRemittanceDigestEngine {
        var steps: [any DefaultRemittanceDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRemittanceDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultRemittanceDigest) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [DefaultRemittanceDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultRemittanceDigestEngine(_ flags: Kit.Flags.Registry) -> DefaultRemittanceDigestEngine {
        return DefaultRemittanceDigestEngine(
            steps: [
                RoundingDefaultRemittanceDigestAdjuster(step: 0.5),
                TieredDefaultRemittanceDigestAdjuster(bounds: [5032.0, 9770.0], rates: [1.18, 0.92]),
                FlaggedDefaultRemittanceDigestAdjuster(
                    flags: flags,
                    flag: "default-remittance-digest-manual",
                    percent: 0.8
                ),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 3476.8
        )
    }
}
