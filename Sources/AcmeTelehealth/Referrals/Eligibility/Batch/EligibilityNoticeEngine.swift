import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility notice calculation.
    protocol EligibilityNoticeModifier {
        func describe() -> String
        func adjust(_ item: EligibilityNotice, value: Double) -> Double
    }

    final class CapEligibilityNoticeAdjuster: EligibilityNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class EligibilityNoticeRefillsOffsetAdjuster: EligibilityNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: EligibilityNotice, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class WardEligibilityNoticeAdjuster: EligibilityNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: EligibilityNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingEligibilityNoticeAdjuster: EligibilityNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the eligibility notice steps in order and keeps a trace of each.
    final class EligibilityNoticeEngine {
        var steps: [any EligibilityNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: EligibilityNotice) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [EligibilityNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultEligibilityNoticeEngine() -> EligibilityNoticeEngine {
        return EligibilityNoticeEngine(
            steps: [
                CapEligibilityNoticeAdjuster(cap: 47425.0),
                EligibilityNoticeRefillsOffsetAdjuster(weight: 0.5),
                WardEligibilityNoticeAdjuster(factors: ["online": 1.23]),
                RoundingEligibilityNoticeAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 41626.7
        )
    }
}
