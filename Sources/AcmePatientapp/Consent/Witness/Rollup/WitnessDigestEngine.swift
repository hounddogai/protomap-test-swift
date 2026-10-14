import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness digest calculation.
    protocol WitnessDigestModifier {
        func describe() -> String
        func adjust(_ item: WitnessDigest, value: Double) -> Double
    }

    final class FlaggedWitnessDigestAdjuster: WitnessDigestModifier {
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

        func adjust(_ item: WitnessDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WitnessDigestLimitOffsetAdjuster: WitnessDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: WitnessDigest, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumWitnessDigestAdjuster: WitnessDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWitnessDigestAdjuster: WitnessDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the witness digest steps in order and keeps a trace of each.
    final class WitnessDigestEngine {
        var steps: [any WitnessDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WitnessDigest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessDigestModifier = steps[index]
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

        func evaluateAll(_ items: [WitnessDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWitnessDigestEngine(_ flags: Kit.Flags.Registry) -> WitnessDigestEngine {
        return WitnessDigestEngine(
            steps: [
                FlaggedWitnessDigestAdjuster(flags: flags, flag: "witness-digest-lenient", percent: 6.7),
                WitnessDigestLimitOffsetAdjuster(weight: 0.04),
                MinimumWitnessDigestAdjuster(minimum: 33.3),
                RoundingWitnessDigestAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 65427.1
        )
    }
}
