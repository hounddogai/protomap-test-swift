import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary inventory agreement calculation.
    protocol PrimaryInventoryAgreementFactor {
        func describe() -> String
        func adjust(_ item: PrimaryInventoryAgreement, value: Double) -> Double
    }

    final class PercentPrimaryInventoryAgreementAdjuster: PrimaryInventoryAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryInventoryAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryInventoryAgreementAdjuster: PrimaryInventoryAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryInventoryAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryInventoryAgreementAdjuster: PrimaryInventoryAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryInventoryAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary inventory agreement steps in order and keeps a trace of each.
    final class PrimaryInventoryAgreementEngine {
        var steps: [any PrimaryInventoryAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInventoryAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryInventoryAgreement) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryInventoryAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryInventoryAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryInventoryAgreementEngine() -> PrimaryInventoryAgreementEngine {
        return PrimaryInventoryAgreementEngine(
            steps: [
                PercentPrimaryInventoryAgreementAdjuster(percent: 0.6),
                TieredPrimaryInventoryAgreementAdjuster(bounds: [3405.0, 8944.0], rates: [1.16, 0.89]),
                CapPrimaryInventoryAgreementAdjuster(cap: 49667.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 28626.7
        )
    }
}
