import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling accession score calculation.
    protocol RollingAccessionScoreModifier {
        func describe() -> String
        func adjust(_ item: RollingAccessionScore, value: Double) -> Double
    }

    final class NameRollingAccessionScoreAdjuster: RollingAccessionScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingAccessionScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRollingAccessionScoreAdjuster: RollingAccessionScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingAccessionScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingAccessionScoreAdjuster: RollingAccessionScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingAccessionScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingAccessionScoreAdjuster: RollingAccessionScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingAccessionScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RollingAccessionScoreRatioOffsetAdjuster: RollingAccessionScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: RollingAccessionScore, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedRollingAccessionScoreAdjuster: RollingAccessionScoreModifier {
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

        func adjust(_ item: RollingAccessionScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling accession score steps in order and keeps a trace of each.
    final class RollingAccessionScoreEngine {
        var steps: [any RollingAccessionScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAccessionScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingAccessionScore) -> Double {
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

        func evaluateAll(_ items: [RollingAccessionScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingAccessionScoreEngine(_ flags: Kit.Flags.Registry) -> RollingAccessionScoreEngine {
        return RollingAccessionScoreEngine(
            steps: [
                NameRollingAccessionScoreAdjuster(factors: ["west": 0.74, "north": 0.87, "retail": 1.0]),
                RoundingRollingAccessionScoreAdjuster(step: 0.25),
                CapRollingAccessionScoreAdjuster(cap: 23534.0),
                MinimumRollingAccessionScoreAdjuster(minimum: 30.1),
                RollingAccessionScoreRatioOffsetAdjuster(weight: 0.97),
                FlaggedRollingAccessionScoreAdjuster(
                    flags: flags,
                    flag: "rolling-accession-score-adaptive",
                    percent: -1.6
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 11822.0
        )
    }
}
