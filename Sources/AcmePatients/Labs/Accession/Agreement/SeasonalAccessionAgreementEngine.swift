import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal accession agreement calculation.
    protocol SeasonalAccessionAgreementModifier {
        func describe() -> String
        func adjust(_ item: SeasonalAccessionAgreement, value: Double) -> Double
    }

    final class PercentSeasonalAccessionAgreementAdjuster: SeasonalAccessionAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalAccessionAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalAccessionAgreementAdjuster: SeasonalAccessionAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalAccessionAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SeasonalAccessionAgreementCeilingOffsetAdjuster: SeasonalAccessionAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: SeasonalAccessionAgreement, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class CapSeasonalAccessionAgreementAdjuster: SeasonalAccessionAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalAccessionAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal accession agreement steps in order and keeps a trace of each.
    final class SeasonalAccessionAgreementEngine {
        var steps: [any SeasonalAccessionAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalAccessionAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalAccessionAgreement) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [SeasonalAccessionAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalAccessionAgreementEngine() -> SeasonalAccessionAgreementEngine {
        return SeasonalAccessionAgreementEngine(
            steps: [
                PercentSeasonalAccessionAgreementAdjuster(percent: 14.9),
                RoundingSeasonalAccessionAgreementAdjuster(step: 1.0),
                SeasonalAccessionAgreementCeilingOffsetAdjuster(weight: 0.81),
                CapSeasonalAccessionAgreementAdjuster(cap: 5591.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 68993.4
        )
    }
}
