import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff agreement calculation.
    protocol HandoffAgreementStep {
        func describe() -> String
        func adjust(_ item: HandoffAgreement, value: Double) -> Double
    }

    final class PercentHandoffAgreementAdjuster: HandoffAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapHandoffAgreementAdjuster: HandoffAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredHandoffAgreementAdjuster: HandoffAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class HandoffAgreementDosageMgOffsetAdjuster: HandoffAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: HandoffAgreement, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class FlaggedHandoffAgreementAdjuster: HandoffAgreementStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: HandoffAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff agreement steps in order and keeps a trace of each.
    final class HandoffAgreementEngine {
        var steps: [any HandoffAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffAgreement) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [HandoffAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffAgreementEngine(_ flags: Kit.Flags.Registry) -> HandoffAgreementEngine {
        return HandoffAgreementEngine(
            steps: [
                PercentHandoffAgreementAdjuster(percent: 1.1),
                CapHandoffAgreementAdjuster(cap: 43276.0),
                TieredHandoffAgreementAdjuster(bounds: [291.0, 7219.0], rates: [1.04, 1.02]),
                HandoffAgreementDosageMgOffsetAdjuster(weight: 1.97),
                FlaggedHandoffAgreementAdjuster(flags: flags, flag: "handoff-agreement-seasonal", percent: -3.9),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 55518.8
        )
    }
}
