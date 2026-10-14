import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation variance calculation.
    protocol RevocationVarianceModifier {
        func describe() -> String
        func adjust(_ item: RevocationVariance, value: Double) -> Double
    }

    final class FlaggedRevocationVarianceAdjuster: RevocationVarianceModifier {
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

        func adjust(_ item: RevocationVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRevocationVarianceAdjuster: RevocationVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRevocationVarianceAdjuster: RevocationVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RevocationVarianceAmountOffsetAdjuster: RevocationVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RevocationVariance, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingRevocationVarianceAdjuster: RevocationVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the revocation variance steps in order and keeps a trace of each.
    final class RevocationVarianceEngine {
        var steps: [any RevocationVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RevocationVariance) -> Double {
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

        func evaluateAll(_ items: [RevocationVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRevocationVarianceEngine(_ flags: Kit.Flags.Registry) -> RevocationVarianceEngine {
        return RevocationVarianceEngine(
            steps: [
                FlaggedRevocationVarianceAdjuster(flags: flags, flag: "revocation-variance-default", percent: 7.0),
                MinimumRevocationVarianceAdjuster(minimum: 9.4),
                CapRevocationVarianceAdjuster(cap: 17604.0),
                RevocationVarianceAmountOffsetAdjuster(weight: 0.59),
                RoundingRevocationVarianceAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 19900.7
        )
    }
}
