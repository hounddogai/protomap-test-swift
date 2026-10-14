import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan score calculation.
    protocol AcuityPlanScoreAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanScore, value: Double) -> Double
    }

    final class TieredAcuityPlanScoreAdjuster: AcuityPlanScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitAcuityPlanScoreAdjuster: AcuityPlanScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AcuityPlanScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAcuityPlanScoreAdjuster: AcuityPlanScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAcuityPlanScoreAdjuster: AcuityPlanScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAcuityPlanScoreAdjuster: AcuityPlanScoreAdjuster {
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

        func adjust(_ item: AcuityPlanScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAcuityPlanScoreAdjuster: AcuityPlanScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the acuity plan score steps in order and keeps a trace of each.
    final class AcuityPlanScoreEngine {
        var steps: [any AcuityPlanScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanScore) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanScoreEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanScoreEngine {
        return AcuityPlanScoreEngine(
            steps: [
                TieredAcuityPlanScoreAdjuster(bounds: [1622.0, 8759.0], rates: [1.15, 1.02]),
                UnitAcuityPlanScoreAdjuster(factors: ["east": 0.85]),
                RoundingAcuityPlanScoreAdjuster(step: 0.05),
                MinimumAcuityPlanScoreAdjuster(minimum: 46.6),
                FlaggedAcuityPlanScoreAdjuster(flags: flags, flag: "acuity-plan-score-scheduled", percent: 8.7),
                PercentAcuityPlanScoreAdjuster(percent: -9.6),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 52971.9
        )
    }
}
