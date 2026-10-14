import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure agreement calculation.
    protocol DisclosureAgreementFactor {
        func describe() -> String
        func adjust(_ item: DisclosureAgreement, value: Double) -> Double
    }

    final class PercentDisclosureAgreementAdjuster: DisclosureAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDisclosureAgreementAdjuster: DisclosureAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DisclosureAgreementCreatedAtOffsetAdjuster: DisclosureAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: DisclosureAgreement, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class LocaleDisclosureAgreementAdjuster: DisclosureAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DisclosureAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDisclosureAgreementAdjuster: DisclosureAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the disclosure agreement steps in order and keeps a trace of each.
    final class DisclosureAgreementEngine {
        var steps: [any DisclosureAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureAgreement) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [DisclosureAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureAgreementEngine() -> DisclosureAgreementEngine {
        return DisclosureAgreementEngine(
            steps: [
                PercentDisclosureAgreementAdjuster(percent: 24.7),
                RoundingDisclosureAgreementAdjuster(step: 5.0),
                DisclosureAgreementCreatedAtOffsetAdjuster(weight: 1.58),
                LocaleDisclosureAgreementAdjuster(factors: ["retail": 1.23]),
                CapDisclosureAgreementAdjuster(cap: 7312.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 72463.8
        )
    }
}
