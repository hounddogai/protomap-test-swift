import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction agreement calculation.
    protocol InteractionAgreementModifier {
        func describe() -> String
        func adjust(_ item: InteractionAgreement, value: Double) -> Double
    }

    final class PercentInteractionAgreementAdjuster: InteractionAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapInteractionAgreementAdjuster: InteractionAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceInteractionAgreementAdjuster: InteractionAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: InteractionAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingInteractionAgreementAdjuster: InteractionAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the interaction agreement steps in order and keeps a trace of each.
    final class InteractionAgreementEngine {
        var steps: [any InteractionAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionAgreement) -> Double {
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

        func evaluateAll(_ items: [InteractionAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionAgreementEngine() -> InteractionAgreementEngine {
        return InteractionAgreementEngine(
            steps: [
                PercentInteractionAgreementAdjuster(percent: -1.7),
                CapInteractionAgreementAdjuster(cap: 18884.0),
                SourceInteractionAgreementAdjuster(factors: ["south": 1.18]),
                RoundingInteractionAgreementAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 2128.8
        )
    }
}
