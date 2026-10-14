import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation target calculation.
    protocol RevocationTargetAdjuster {
        func describe() -> String
        func adjust(_ item: RevocationTarget, value: Double) -> Double
    }

    final class CapRevocationTargetAdjuster: RevocationTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRevocationTargetAdjuster: RevocationTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleRevocationTargetAdjuster: RevocationTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RevocationTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRevocationTargetAdjuster: RevocationTargetAdjuster {
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

        func adjust(_ item: RevocationTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RevocationTargetDurationMinutesOffsetAdjuster: RevocationTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: RevocationTarget, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the revocation target steps in order and keeps a trace of each.
    final class RevocationTargetEngine {
        var steps: [any RevocationTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RevocationTarget) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [RevocationTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRevocationTargetEngine(_ flags: Kit.Flags.Registry) -> RevocationTargetEngine {
        return RevocationTargetEngine(
            steps: [
                CapRevocationTargetAdjuster(cap: 821.0),
                RoundingRevocationTargetAdjuster(step: 0.05),
                TitleRevocationTargetAdjuster(factors: ["central": 1.08, "north": 1.35, "online": 0.99]),
                FlaggedRevocationTargetAdjuster(flags: flags, flag: "revocation-target-strict", percent: -3.7),
                RevocationTargetDurationMinutesOffsetAdjuster(weight: 1.85),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 34554.5
        )
    }
}
