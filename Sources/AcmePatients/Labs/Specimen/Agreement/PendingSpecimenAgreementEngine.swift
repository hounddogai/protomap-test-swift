import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending specimen agreement calculation.
    protocol PendingSpecimenAgreementStep {
        func describe() -> String
        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double
    }

    final class TieredPendingSpecimenAgreementAdjuster: PendingSpecimenAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPendingSpecimenAgreementAdjuster: PendingSpecimenAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingSpecimenAgreementAdjuster: PendingSpecimenAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingSpecimenAgreementAdjuster: PendingSpecimenAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelPendingSpecimenAgreementAdjuster: PendingSpecimenAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingSpecimenAgreementAdjuster: PendingSpecimenAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingSpecimenAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending specimen agreement steps in order and keeps a trace of each.
    final class PendingSpecimenAgreementEngine {
        var steps: [any PendingSpecimenAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSpecimenAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingSpecimenAgreement) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [PendingSpecimenAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingSpecimenAgreementEngine() -> PendingSpecimenAgreementEngine {
        return PendingSpecimenAgreementEngine(
            steps: [
                TieredPendingSpecimenAgreementAdjuster(bounds: [4495.0, 7587.0, 9991.0], rates: [0.85, 0.87, 0.94]),
                MinimumPendingSpecimenAgreementAdjuster(minimum: 41.9),
                CapPendingSpecimenAgreementAdjuster(cap: 7487.0),
                RoundingPendingSpecimenAgreementAdjuster(step: 0.5),
                LabelPendingSpecimenAgreementAdjuster(factors: ["north": 0.95, "east": 1.25, "west": 0.93]),
                PercentPendingSpecimenAgreementAdjuster(percent: 8.2),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 81180.1
        )
    }
}
