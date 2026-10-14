import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling revocation exception calculation.
    protocol RollingRevocationExceptionStep {
        func describe() -> String
        func adjust(_ item: RollingRevocationException, value: Double) -> Double
    }

    final class FlaggedRollingRevocationExceptionAdjuster: RollingRevocationExceptionStep {
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

        func adjust(_ item: RollingRevocationException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingRevocationExceptionAmountOffsetAdjuster: RollingRevocationExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RollingRevocationException, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumRollingRevocationExceptionAdjuster: RollingRevocationExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingRevocationException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRollingRevocationExceptionAdjuster: RollingRevocationExceptionStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingRevocationException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling revocation exception steps in order and keeps a trace of each.
    final class RollingRevocationExceptionEngine {
        var steps: [any RollingRevocationExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRevocationExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingRevocationException) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [RollingRevocationException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingRevocationExceptionEngine(_ flags: Kit.Flags.Registry) -> RollingRevocationExceptionEngine {
        return RollingRevocationExceptionEngine(
            steps: [
                FlaggedRollingRevocationExceptionAdjuster(
                    flags: flags,
                    flag: "rolling-revocation-exception-legacy",
                    percent: 5.3
                ),
                RollingRevocationExceptionAmountOffsetAdjuster(weight: 1.37),
                MinimumRollingRevocationExceptionAdjuster(minimum: 9.8),
                RoundingRollingRevocationExceptionAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 72537.6
        )
    }
}
