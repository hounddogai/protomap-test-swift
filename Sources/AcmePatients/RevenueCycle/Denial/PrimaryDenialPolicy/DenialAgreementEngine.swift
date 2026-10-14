import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial agreement calculation.
    protocol DenialAgreementModifier {
        func describe() -> String
        func adjust(_ item: DenialAgreement, value: Double) -> Double
    }

    final class TieredDenialAgreementAdjuster: DenialAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DenialAgreementMaximumOffsetAdjuster: DenialAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: DenialAgreement, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapDenialAgreementAdjuster: DenialAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the denial agreement steps in order and keeps a trace of each.
    final class DenialAgreementEngine {
        var steps: [any DenialAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialAgreement) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [DenialAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialAgreementEngine() -> DenialAgreementEngine {
        return DenialAgreementEngine(
            steps: [
                TieredDenialAgreementAdjuster(bounds: [2639.0, 6079.0], rates: [0.96, 0.96]),
                DenialAgreementMaximumOffsetAdjuster(weight: 1.42),
                CapDenialAgreementAdjuster(cap: 21080.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 54432.5
        )
    }
}
