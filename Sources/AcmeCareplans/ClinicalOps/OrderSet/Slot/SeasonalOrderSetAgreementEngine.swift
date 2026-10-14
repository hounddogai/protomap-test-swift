import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal order set agreement calculation.
    protocol SeasonalOrderSetAgreementModifier {
        func describe() -> String
        func adjust(_ item: SeasonalOrderSetAgreement, value: Double) -> Double
    }

    final class SeasonalOrderSetAgreementDosageMgOffsetAdjuster: SeasonalOrderSetAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: SeasonalOrderSetAgreement, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentSeasonalOrderSetAgreementAdjuster: SeasonalOrderSetAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalOrderSetAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalOrderSetAgreementAdjuster: SeasonalOrderSetAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalOrderSetAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalOrderSetAgreementAdjuster: SeasonalOrderSetAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalOrderSetAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal order set agreement steps in order and keeps a trace of each.
    final class SeasonalOrderSetAgreementEngine {
        var steps: [any SeasonalOrderSetAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalOrderSetAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalOrderSetAgreement) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalOrderSetAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalOrderSetAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalOrderSetAgreementEngine() -> SeasonalOrderSetAgreementEngine {
        return SeasonalOrderSetAgreementEngine(
            steps: [
                SeasonalOrderSetAgreementDosageMgOffsetAdjuster(weight: 0.66),
                PercentSeasonalOrderSetAgreementAdjuster(percent: 21.0),
                RoundingSeasonalOrderSetAgreementAdjuster(step: 0.05),
                CapSeasonalOrderSetAgreementAdjuster(cap: 49475.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 69065.1
        )
    }
}
