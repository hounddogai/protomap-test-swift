import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score mapping calculation.
    protocol RiskScoreMappingModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreMapping, value: Double) -> Double
    }

    final class PercentRiskScoreMappingAdjuster: RiskScoreMappingModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRiskScoreMappingAdjuster: RiskScoreMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RiskScoreMappingRateOffsetAdjuster: RiskScoreMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RiskScoreMapping, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumRiskScoreMappingAdjuster: RiskScoreMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRiskScoreMappingAdjuster: RiskScoreMappingModifier {
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

        func adjust(_ item: RiskScoreMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score mapping steps in order and keeps a trace of each.
    final class RiskScoreMappingEngine {
        var steps: [any RiskScoreMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreMapping) -> Double {
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

        func evaluateAll(_ items: [RiskScoreMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreMappingEngine(_ flags: Kit.Flags.Registry) -> RiskScoreMappingEngine {
        return RiskScoreMappingEngine(
            steps: [
                PercentRiskScoreMappingAdjuster(percent: -2.8),
                CapRiskScoreMappingAdjuster(cap: 4567.0),
                RiskScoreMappingRateOffsetAdjuster(weight: 0.5),
                MinimumRiskScoreMappingAdjuster(minimum: 18.1),
                FlaggedRiskScoreMappingAdjuster(flags: flags, flag: "risk-score-mapping-default", percent: -1.9),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 26937.3
        )
    }
}
