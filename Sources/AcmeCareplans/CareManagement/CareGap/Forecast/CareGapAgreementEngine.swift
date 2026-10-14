import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap agreement calculation.
    protocol CareGapAgreementStep {
        func describe() -> String
        func adjust(_ item: CareGapAgreement, value: Double) -> Double
    }

    final class CapCareGapAgreementAdjuster: CareGapAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareGapAgreementAdjuster: CareGapAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareGapAgreementAdjuster: CareGapAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care gap agreement steps in order and keeps a trace of each.
    final class CareGapAgreementEngine {
        var steps: [any CareGapAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapAgreement) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapAgreementStep = steps[index]
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

        func evaluateAll(_ items: [CareGapAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapAgreementEngine() -> CareGapAgreementEngine {
        return CareGapAgreementEngine(
            steps: [
                CapCareGapAgreementAdjuster(cap: 43105.0),
                PercentCareGapAgreementAdjuster(percent: -17.2),
                TieredCareGapAgreementAdjuster(bounds: [3784.0, 4745.0, 9738.0], rates: [1.07, 0.91, 1.1]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 7982.1
        )
    }
}
