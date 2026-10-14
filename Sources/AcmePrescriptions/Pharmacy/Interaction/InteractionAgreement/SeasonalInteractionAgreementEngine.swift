import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal interaction agreement calculation.
    protocol SeasonalInteractionAgreementStep {
        func describe() -> String
        func adjust(_ item: SeasonalInteractionAgreement, value: Double) -> Double
    }

    final class PercentSeasonalInteractionAgreementAdjuster: SeasonalInteractionAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalInteractionAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalInteractionAgreementAdjuster: SeasonalInteractionAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalInteractionAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalInteractionAgreementAdjuster: SeasonalInteractionAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalInteractionAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalInteractionAgreementAdjuster: SeasonalInteractionAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalInteractionAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SeasonalInteractionAgreementFloorValueOffsetAdjuster: SeasonalInteractionAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: SeasonalInteractionAgreement, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the seasonal interaction agreement steps in order and keeps a trace of each.
    final class SeasonalInteractionAgreementEngine {
        var steps: [any SeasonalInteractionAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalInteractionAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalInteractionAgreement) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [SeasonalInteractionAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalInteractionAgreementEngine() -> SeasonalInteractionAgreementEngine {
        return SeasonalInteractionAgreementEngine(
            steps: [
                PercentSeasonalInteractionAgreementAdjuster(percent: -21.0),
                RoundingSeasonalInteractionAgreementAdjuster(step: 0.05),
                CapSeasonalInteractionAgreementAdjuster(cap: 33183.0),
                MinimumSeasonalInteractionAgreementAdjuster(minimum: 23.9),
                SeasonalInteractionAgreementFloorValueOffsetAdjuster(weight: 0.54),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 78638.5
        )
    }
}
