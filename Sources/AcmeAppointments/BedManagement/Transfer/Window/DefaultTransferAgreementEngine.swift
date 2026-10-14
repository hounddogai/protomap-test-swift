import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default transfer agreement calculation.
    protocol DefaultTransferAgreementStep {
        func describe() -> String
        func adjust(_ item: DefaultTransferAgreement, value: Double) -> Double
    }

    final class RoundingDefaultTransferAgreementAdjuster: DefaultTransferAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultTransferAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultTransferAgreementAdjuster: DefaultTransferAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultTransferAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDefaultTransferAgreementAdjuster: DefaultTransferAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultTransferAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default transfer agreement steps in order and keeps a trace of each.
    final class DefaultTransferAgreementEngine {
        var steps: [any DefaultTransferAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultTransferAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultTransferAgreement) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [DefaultTransferAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultTransferAgreementEngine() -> DefaultTransferAgreementEngine {
        return DefaultTransferAgreementEngine(
            steps: [
                RoundingDefaultTransferAgreementAdjuster(step: 0.1),
                TieredDefaultTransferAgreementAdjuster(
                    bounds: [3374.0, 3994.0, 7726.0, 8243.0],
                    rates: [1.18, 0.89, 0.86, 0.98]
                ),
                CapDefaultTransferAgreementAdjuster(cap: 18626.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 84345.1
        )
    }
}
