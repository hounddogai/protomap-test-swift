import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary rounding score calculation.
    protocol PrimaryRoundingScoreStep {
        func describe() -> String
        func adjust(_ item: PrimaryRoundingScore, value: Double) -> Double
    }

    final class PrimaryRoundingScoreAmountOffsetAdjuster: PrimaryRoundingScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: PrimaryRoundingScore, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumPrimaryRoundingScoreAdjuster: PrimaryRoundingScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryRoundingScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocalePrimaryRoundingScoreAdjuster: PrimaryRoundingScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PrimaryRoundingScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryRoundingScoreAdjuster: PrimaryRoundingScoreStep {
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

        func adjust(_ item: PrimaryRoundingScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary rounding score steps in order and keeps a trace of each.
    final class PrimaryRoundingScoreEngine {
        var steps: [any PrimaryRoundingScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryRoundingScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryRoundingScore) -> Double {
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

        func evaluateAll(_ items: [PrimaryRoundingScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryRoundingScoreEngine(_ flags: Kit.Flags.Registry) -> PrimaryRoundingScoreEngine {
        return PrimaryRoundingScoreEngine(
            steps: [
                PrimaryRoundingScoreAmountOffsetAdjuster(weight: 1.59),
                MinimumPrimaryRoundingScoreAdjuster(minimum: 44.2),
                LocalePrimaryRoundingScoreAdjuster(factors: ["north": 1.37, "online": 0.94]),
                FlaggedPrimaryRoundingScoreAdjuster(
                    flags: flags,
                    flag: "primary-rounding-score-fallback",
                    percent: -8.5
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 85459.2
        )
    }
}
