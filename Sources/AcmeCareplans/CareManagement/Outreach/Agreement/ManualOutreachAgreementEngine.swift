import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual outreach agreement calculation.
    protocol ManualOutreachAgreementFactor {
        func describe() -> String
        func adjust(_ item: ManualOutreachAgreement, value: Double) -> Double
    }

    final class PercentManualOutreachAgreementAdjuster: ManualOutreachAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualOutreachAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualOutreachAgreementAdjuster: ManualOutreachAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualOutreachAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualOutreachAgreementAdjuster: ManualOutreachAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualOutreachAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualOutreachAgreementAdjuster: ManualOutreachAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualOutreachAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual outreach agreement steps in order and keeps a trace of each.
    final class ManualOutreachAgreementEngine {
        var steps: [any ManualOutreachAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOutreachAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualOutreachAgreement) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ManualOutreachAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualOutreachAgreementEngine() -> ManualOutreachAgreementEngine {
        return ManualOutreachAgreementEngine(
            steps: [
                PercentManualOutreachAgreementAdjuster(percent: 17.8),
                TieredManualOutreachAgreementAdjuster(
                    bounds: [1307.0, 1969.0, 2406.0, 9947.0],
                    rates: [1.0, 0.88, 0.89, 1.2]
                ),
                RoundingManualOutreachAgreementAdjuster(step: 5.0),
                MinimumManualOutreachAgreementAdjuster(minimum: 27.5),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 3151.6
        )
    }
}
