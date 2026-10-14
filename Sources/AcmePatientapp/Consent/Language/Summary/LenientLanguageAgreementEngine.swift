import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient language agreement calculation.
    protocol LenientLanguageAgreementModifier {
        func describe() -> String
        func adjust(_ item: LenientLanguageAgreement, value: Double) -> Double
    }

    final class FlaggedLenientLanguageAgreementAdjuster: LenientLanguageAgreementModifier {
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

        func adjust(_ item: LenientLanguageAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientLanguageAgreementCreatedAtOffsetAdjuster: LenientLanguageAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: LenientLanguageAgreement, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class RoundingLenientLanguageAgreementAdjuster: LenientLanguageAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientLanguageAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientLanguageAgreementAdjuster: LenientLanguageAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientLanguageAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleLenientLanguageAgreementAdjuster: LenientLanguageAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientLanguageAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient language agreement steps in order and keeps a trace of each.
    final class LenientLanguageAgreementEngine {
        var steps: [any LenientLanguageAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientLanguageAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientLanguageAgreement) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientLanguageAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [LenientLanguageAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientLanguageAgreementEngine(_ flags: Kit.Flags.Registry) -> LenientLanguageAgreementEngine {
        return LenientLanguageAgreementEngine(
            steps: [
                FlaggedLenientLanguageAgreementAdjuster(
                    flags: flags,
                    flag: "lenient-language-agreement-adaptive",
                    percent: 3.1
                ),
                LenientLanguageAgreementCreatedAtOffsetAdjuster(weight: 0.8),
                RoundingLenientLanguageAgreementAdjuster(step: 0.05),
                TieredLenientLanguageAgreementAdjuster(
                    bounds: [4087.0, 5354.0, 6521.0, 7240.0],
                    rates: [0.88, 0.84, 1.13, 0.85]
                ),
                TitleLenientLanguageAgreementAdjuster(factors: ["central": 1.22, "retail": 0.98, "west": 0.74]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 66628.3
        )
    }
}
