import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation rollup calculation.
    protocol RevocationRollupFactor {
        func describe() -> String
        func adjust(_ item: RevocationRollup, value: Double) -> Double
    }

    final class FlaggedRevocationRollupAdjuster: RevocationRollupFactor {
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

        func adjust(_ item: RevocationRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRevocationRollupAdjuster: RevocationRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRevocationRollupAdjuster: RevocationRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the revocation rollup steps in order and keeps a trace of each.
    final class RevocationRollupEngine {
        var steps: [any RevocationRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RevocationRollup) -> Double {
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

        func evaluateAll(_ items: [RevocationRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRevocationRollupEngine(_ flags: Kit.Flags.Registry) -> RevocationRollupEngine {
        return RevocationRollupEngine(
            steps: [
                FlaggedRevocationRollupAdjuster(flags: flags, flag: "revocation-rollup-seasonal", percent: -9.6),
                MinimumRevocationRollupAdjuster(minimum: 48.3),
                PercentRevocationRollupAdjuster(percent: 1.4),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 93487.2
        )
    }
}
